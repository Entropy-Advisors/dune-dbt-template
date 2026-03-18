{{
    config(
        alias = 'stg_token_holder_transfers',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'tx_hash', 'evt_index', 'event_type'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}

-- All ERC-20/native transfers for tokens whitelisted in dim_labels, split into two rows per event:
-- one inflow row (wallet_address = "to", amount positive) and one outflow row (wallet_address = "from",
-- amount negative). Together, this produces a signed ledger of wallet-level token movements.
--
-- Mint and burn events are included — they represent real balance changes for the recipient/sender.
-- The zero address (0x0) is excluded as a wallet_address in both branches because it is not a holder.
--
-- Fed by: tokens.transfers (Dune source), dim_labels (token whitelist + min_block_number filter).
-- Feeds:  int_token_holder_daily_net_change.
--
-- Signed amounts: all three amount fields are signed — positive for inflows, negative for outflows.
-- Unique key: (blockchain, tx_hash, evt_index, event_type) — event_type differentiates the two rows
-- produced from a single transfer event.
--
-- Incremental: delete+insert on (blockchain, block_date), 3-day lookback.

with

labels as (
    select
        blockchain,
        address,
        category,
        min_block_number,
        min_block_time
    from {{ ref('dim_labels') }}
    -- where type = 'token'
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
        l.min_block_time
    from {{ source('tokens', 'transfers') }} as t
    inner join labels as l
        on  t.blockchain       = l.blockchain
        and t.contract_address = l.address
    where
        (t.blockchain, t.contract_address) in (select blockchain, address from labels)
        and token_standard in ('erc20', 'native')
        and t.block_number >= l.min_block_number
        {%- if is_incremental() %}
        and t.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
),

inflow as (
    select
        blockchain,
        'inflow'                                                                   as event_type,
        symbol,
        contract_address,
        category,
        min_block_time,
        tx_hash,
        tx_from,
        tx_to,
        tx_index,
        evt_index,
        block_time,
        block_number,
        block_date,
        "to"                                                                       as wallet_address,
        cast(amount_raw as double)                                                 as amount_raw,
        cast(amount as double)                                                     as amount,
        price_usd                                                                  as price,
        cast(amount_usd as double)                                                 as amount_usd
    from transfers
    where "to" != 0x0000000000000000000000000000000000000000
),

outflow as (
    select
        blockchain,
        'outflow'                                                                  as event_type,
        symbol,
        contract_address,
        category,
        min_block_time,
        tx_hash,
        tx_from,
        tx_to,
        tx_index,
        evt_index,
        block_time,
        block_number,
        block_date,
        "from"                                                                     as wallet_address,
        -cast(amount_raw as double)                                                as amount_raw,
        -cast(amount as double)                                                    as amount,
        price_usd                                                                  as price,
        -cast(amount_usd as double)                                                as amount_usd
    from transfers
    where "from" != 0x0000000000000000000000000000000000000000
)

select * from inflow
union all
select * from outflow