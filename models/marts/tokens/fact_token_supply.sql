{{
    config(
        alias = 'fact_token_supply',
        materialized = 'table'
    )
}}

select
    s.date,
    blockchain,
    s.contract_address,
    s.symbol,
    s.category,
    p.price,
    s.mint_volume,
    s.burn_volume,
    s.net_change,
    s.mint_volume_cumulative,
    s.burn_volume_cumulative,
    s.circulating_supply,
    s.circulating_supply * p.price as market_cap
from
    {{ ref('int_token_daily_supply') }} as s
    left join {{ source('prices', 'day') }} as p on s.date = p.day
        and s.blockchain = p.blockchain
        and s.contract_address = p.contract_address