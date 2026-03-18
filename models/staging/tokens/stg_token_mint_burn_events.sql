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

-- Mint and burn transfer events for tokens whitelisted in dim_labels.
-- One row per transfer event where "from" = 0x0 (mint) or "to" = 0x0 (burn).
--
-- Fed by: tokens.transfers (Dune source), dim_labels (token whitelist + min_block_number filter).
-- Feeds:  int_token_daily_net_change.
--
-- Whitelist: dim_labels controls both which tokens and which chains are scanned.
-- Adding a new token or chain requires only a new row in dim_labels — no SQL changes here.
--
-- Signed amounts: all three amount fields (amount_raw, amount, amount_usd) are signed —
-- positive = mint, negative = burn. This differs from stg_dex_pool_token_transfers where
-- amount_raw is also signed. See CLAUDE.md → "Signed amount convention".
--
-- Incremental: delete+insert on (blockchain, block_date), 3-day lookback.

with

labels as (
    select
        blockchain,
        address,
        category,
        start_block
    from
        {{ ref('dim_labels') }}
    where
        type = 'token'
)

select
    t.block_time,
    t.blockchain,
    t.contract_address,
    t.symbol,
    l.category,
    t.amount,
    case
        when t."from" = 0x0000000000000000000000000000000000000000 then 'mint'
        when t."to"   = 0x0000000000000000000000000000000000000000 then 'burn'
    end as transfer_type
from
    {{ source('tokens', 'transfers') }} as t
    join labels as l on t.contract_address = l.address
        and t.blockchain = l.blockchain
where
    t.block_number >= l.start_block
    and (
        t."from" = 0x0000000000000000000000000000000000000000
        or t."to" = 0x0000000000000000000000000000000000000000
    )
    {%- if is_incremental() %}
    and t.block_date >= now() - interval '3' day
    {%- endif %}