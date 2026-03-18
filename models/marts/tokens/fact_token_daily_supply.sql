{{
    config(
        alias = 'fact_token_daily_supply',
        materialized = 'table'
    )
}}

-- Daily circulating supply per token per chain.
-- Owns the daily spine, gap-fill, and cumulative columns.
--
-- Fed by: int_token_daily_net_change (daily activity only), dim_labels (spine anchor).
-- Architecture note: intermediate layer is a cheap GROUP BY view; this mart is where the
-- expensive spine cross-join and window functions live — mirrors the DEX convention.
-- Price join deferred — add when a prices source is available.

with

net_changes as (
    select * from {{ ref('int_token_daily_net_change') }}
),

-- Continuous daily spine from each token's deployment date to today.
index as (
    select
        cast(d.timestamp as date)                                               as day,
        l.blockchain,
        l.address                                                               as contract_address,
        l.name                                                                  as symbol,
        l.category
    from {{ source('utils', 'days') }} as d
    cross join {{ ref('dim_labels') }} as l
    where l.type = 'token'
      and d.timestamp >= cast(date_trunc('day', l.min_block_time) as date)
),

-- Gap-filled daily series with cumulative columns.
-- NULL on quiet days for flow columns; cumulative columns carry forward correctly via coalesce.
with_index as (
    select
        d.day                                                                                                        as date,
        d.blockchain,
        d.contract_address,
        d.symbol,
        d.category,
        n.mint_volume,
        n.burn_volume,
        n.net_change,
        sum(coalesce(n.mint_volume, 0)) over (partition by d.blockchain, d.contract_address order by d.day)         as mint_volume_cumulative,
        sum(coalesce(n.burn_volume, 0)) over (partition by d.blockchain, d.contract_address order by d.day)         as burn_volume_cumulative,
        sum(coalesce(n.net_change,  0)) over (partition by d.blockchain, d.contract_address order by d.day)         as circulating_supply
    from index as d
    left join net_changes as n
        on  d.day              = n.day
        and d.blockchain       = n.blockchain
        and d.contract_address = n.contract_address
)

select
    date,
    blockchain,
    contract_address,
    symbol,
    category,
    mint_volume,
    burn_volume,
    net_change,
    mint_volume_cumulative,
    burn_volume_cumulative,
    circulating_supply
from with_index
