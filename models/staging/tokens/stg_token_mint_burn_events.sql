{{
    config(
        alias = 'stg_token_mint_burn_events',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'block_date'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}

-- Raw mint and burn transfer events for tokens labelled in dim_labels.
-- Mints:  transfers FROM the zero address (0x000...000)
-- Burns:  transfers TO the zero address or dead address (0x000...dead)
--
-- Decimal-adjusted amounts and USD values are sourced directly from tokens.transfers.
-- No aggregation — one row per transfer event.

with token_labels as (
    select * from {{ ref('dim_labels') }}
    where type = 'token'
)

select
    t.blockchain,
    t.block_date,
    t.block_time,
    t.block_number,
    t.tx_hash,
    -- t.tx_from          as tx_from_address,  -- transaction sender, available if needed
    -- t.tx_to            as tx_to_address,     -- transaction recipient, available if needed
    -- t.tx_index,                              -- available if needed
    t.evt_index,
    t."from"            as from_address,
    t."to"              as to_address,
    t.contract_address  as token_address,
    t.symbol,
    t.amount,
    t.amount_usd,
    t.price,
    case
        when t."from" = 0x0000000000000000000000000000000000000000
        then 'mint'
        when t."to" in (
            0x0000000000000000000000000000000000000000,
            0x000000000000000000000000000000000000dead
        )
        then 'burn'
    end                 as transfer_type,
    l.name,
    l.label,
    l.category
from
    {{ source('tokens', 'transfers') }} as t
inner join token_labels as l
    on t.contract_address = l.address
    and t.blockchain = l.blockchain
where
    (
        t."from" = 0x0000000000000000000000000000000000000000
        or t."to" in (
            0x0000000000000000000000000000000000000000,
            0x000000000000000000000000000000000000dead
        )
    )
    {%- if is_incremental() %}
    and t.block_date >= now() - interval '3' day
    {%- else %}
    and t.block_date >= date '2026-01-01'
    {%- endif %}
