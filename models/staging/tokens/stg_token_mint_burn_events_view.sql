{{
    config(
        alias = 'stg_token_mint_burn_events_view',
        materialized = 'view'
    )
}}

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
