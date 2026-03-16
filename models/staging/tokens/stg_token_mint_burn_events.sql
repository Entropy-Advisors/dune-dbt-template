{{
    config(
        alias = 'stg_token_mint_burn_events',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'tx_hash', 'evt_index'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}

-- Mint and burn transfer events for tokens whitelisted in dim_labels (type = 'token').
-- One row per transfer event where "from" = 0x0 (mint) or "to" = 0x0 (burn).
--
-- Fed by: tokens.transfers (Dune source), dim_labels (token whitelist + min_block_number filter).
-- Feeds:  int_token_daily_supply.
--
-- Whitelist: dim_labels (type = 'token') controls both which tokens and which chains are scanned.
-- Adding a new token or chain requires only a new row in dim_labels — no SQL changes here.
--
-- Signed amounts: all three amount fields (amount_raw, amount, amount_usd) are signed —
-- positive = mint, negative = burn. This differs from stg_dex_pool_token_transfers where
-- amount_raw is also signed. See CLAUDE.md → "Signed amount convention".
--
-- Incremental: delete+insert on (blockchain, block_date), 3-day lookback.

with

labeled as (
    select
        blockchain,
        address,
        category,
        min_block_number
    from {{ ref('dim_labels') }}
    where type = 'token'
),

transfers as (
    select
        t.blockchain,
        t.contract_address,
        t.symbol,
        t.tx_hash,
        t.tx_from,
        t.tx_to,
        t.tx_index,
        t.evt_index,
        t.block_time,
        t.block_number,
        t.block_date,
        t."from",
        t."to",
        t.amount_raw,
        t.amount,
        t.price_usd,
        t.amount_usd,
        l.category,
        l.min_block_number
    from {{ source('tokens', 'transfers') }} as t
    inner join labeled as l
        on  t.blockchain       = l.blockchain
        and t.contract_address = l.address
    where
        (t.blockchain, t.contract_address) in (select blockchain, address from labeled)
        and t.block_number >= l.min_block_number
        and (
            t."from" = 0x0000000000000000000000000000000000000000
            or  t."to" = 0x0000000000000000000000000000000000000000
        )
        {%- if is_incremental() %}
        and t.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
)

select
    blockchain,
    case
        when "from" = 0x0000000000000000000000000000000000000000 then 'mint'
        when "to"   = 0x0000000000000000000000000000000000000000 then 'burn'
    end                                                                    as event_type,
    symbol,
    contract_address,
    category,
    tx_hash,
    tx_from,
    tx_to,
    tx_index,
    evt_index,
    block_time,
    block_number,
    block_date,
    "from",
    "to",
    -- Signed amounts: positive = tokens entering supply (mint), negative = leaving (burn).
    -- Note: amount_raw is signed here (differs from stg_dex_pool_token_transfers convention).
    -- See CLAUDE.md → "Signed amount convention" for rationale.
    case when "from" = 0x0000000000000000000000000000000000000000
         then  cast(amount_raw as double)
         else -cast(amount_raw as double) end                               as amount_raw,
    case when "from" = 0x0000000000000000000000000000000000000000
         then  cast(amount as double)
         else -cast(amount as double)     end                               as amount,
    price_usd                                                               as price,
    case when "from" = 0x0000000000000000000000000000000000000000
         then  cast(amount_usd as double)
         else -cast(amount_usd as double) end                               as amount_usd
from transfers
