{{
    config(
        alias = 'int_token_daily_supply',
        materialized = 'table'
    )
}}

with

-- Aggregate mint/burn events to daily buckets.
-- amount is signed in staging: positive=mint, negative=burn.
-- burn_volume negates the (already negative) burn amounts to produce a positive volume figure.
supplies as (
    select
        cast(date_trunc('day', block_time) as date)                           as day,
        blockchain,
        contract_address,
        symbol,
        category,
        sum(case when event_type = 'mint' then  amount else 0.0 end)         as mint_volume,
        sum(case when event_type = 'burn' then -amount else 0.0 end)         as burn_volume,
        sum(amount)                                                            as net_change
    from {{ ref('stg_token_mint_burn_events') }}
    group by 1, 2, 3, 4, 5
),

-- Build the continuous daily spine from each token's deployment date to now.
-- symbol and category come from dim_labels (authoritative); min_block_time drives spine start.
dates as (
    select
        cast(d.day as date)                                                    as day,
        l.blockchain,
        l.address                                                              as contract_address,
        l.name                                                                 as symbol,
        l.category
    from {{ source('utils', 'days') }} as d
    cross join {{ ref('dim_labels') }} as l
    where l.type = 'token'
      and d.day >= cast(date_trunc('day', l.min_block_time) as date)
)

select
    d.day                                                                                                     as date,
    d.blockchain,
    d.contract_address,
    d.symbol,
    d.category,
    s.mint_volume,
    s.burn_volume,
    s.net_change,
    sum(coalesce(s.mint_volume, 0)) over (partition by d.blockchain, d.contract_address order by d.day)      as mint_volume_cumulative,
    sum(coalesce(s.burn_volume, 0)) over (partition by d.blockchain, d.contract_address order by d.day)      as burn_volume_cumulative,
    sum(coalesce(s.net_change,  0)) over (partition by d.blockchain, d.contract_address order by d.day)      as circulating_supply
from dates as d
left join supplies as s
    on  d.day              = s.day
    and d.blockchain       = s.blockchain
    and d.contract_address = s.contract_address
