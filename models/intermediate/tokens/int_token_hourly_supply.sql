{{
    config(
        alias = 'int_token_hourly_supply',
        materialized = 'table'
    )
}}

with

supplies as (
    select
        date_trunc('hour', block_time) as date,
        blockchain,
        contract_address,
        symbol,
        category,
        sum(case when transfer_type = 'mint' then amount else 0.0 end) as mint_volume,
        sum(case when transfer_type = 'burn' then amount else 0.0 end) as burn_volume,
        sum(case when transfer_type = 'mint' then amount else 0.0 end)
            - sum(case when transfer_type = 'burn' then amount else 0.0 end) as net_change
    from
        {{ ref('stg_token_mint_burn_events') }}
    group by
        1, 2, 3, 4
),

dates as (
    select
        timestamp,
        blockchain,
        contract_address,
        symbol
    from
        {{ source('utils', 'hours') }}
        cross join (select blockchain, contract_address, symbol, min(date) as start_date from supplies group by 1, 2, 3)
    where
        timestamp >= start_date
)

select
    d.date,
    d.blockchain,
    d.contract_address,
    d.symbol,
    s.mint_volume,
    s.burn_volume,
    s.net_change,
    sum(coalesce(s.mint_volume, 0)) over (partition by d.blockchain, d.contract_address order by d.date) as mint_volume_cumulative,
    sum(coalesce(s.burn_volume, 0)) over (partition by d.blockchain, d.contract_address order by d.date) as burn_volume_cumulative,
    sum(coalesce(s.net_change, 0)) over (partition by d.blockchain, d.contract_address order by d.date) as circulating_supply
from
    dates as d
    left join supplies as s on d.date = s.date
        and d.blockchain = s.blockchain
        and d.contract_address = s.contract_address