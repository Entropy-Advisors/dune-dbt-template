{{
    config(
        alias = 'fact_token_supply',
        materialized = 'table'
    )
}}

with labels as (

    select
        blockchain,
        address         as contract_address,
        start_block
    from
        {{ ref('dim_labels') }}
    where
        type = 'token'

),

transfers as (

    select
        t.block_time,
        t.blockchain,
        t.contract_address,
        t.symbol,
        case when t."from" = 0x0000000000000000000000000000000000000000 then t.amount else 0.0 end as mint_amount,
        case when t."to" = 0x0000000000000000000000000000000000000000 then t.amount else 0.0 end as burn_amount
    from
        {{ source('tokens', 'transfers') }} as t
        join labels as l on t.contract_address = l.contract_address
            and t.blockchain = l.blockchain
    where
        t.block_number >= l.start_block
        and (t."from" = 0x0000000000000000000000000000000000000000 or t."to" = 0x0000000000000000000000000000000000000000)

),

supplies as (

    select
        date_trunc('hour', block_time)          as date,
        blockchain,
        contract_address,
        symbol,
        sum(mint_amount)                        as mint_volume,
        sum(burn_amount)                        as burn_volume,
        sum(mint_amount) - sum(burn_amount)     as net_change
    from
        transfers
    group by
        1, 2, 3, 4

),

dates as (

    select
        timestamp                               as date,
        blockchain,
        contract_address,
        symbol
    from
        {{ source('utils', 'hours') }}
        cross join (select blockchain, contract_address, symbol, min(date) as start_date from supplies group by 1, 2, 3)
    where
        timestamp >= start_date

),

summary as (

    select
        d.date,
        initcap(d.blockchain)                   as blockchain,
        d.contract_address,
        d.symbol,
        p.price,
        s.mint_volume,
        s.burn_volume,
        s.net_change,
        sum(coalesce(s.mint_volume, 0)) over (partition by d.blockchain, d.contract_address order by d.date) as mint_volume_cumulative,
        sum(coalesce(s.burn_volume, 0)) over (partition by d.blockchain, d.contract_address order by d.date) as burn_volume_cumulative,
        sum(coalesce(s.net_change, 0)) over (partition by d.blockchain, d.contract_address order by d.date) as circulating_supply,
        sum(coalesce(s.net_change, 0)) over (partition by d.blockchain, d.contract_address order by d.date) * p.price as market_cap
    from
        dates as d
        left join supplies as s
            on d.date = s.date
            and d.blockchain = s.blockchain
            and d.contract_address = s.contract_address
        left join {{ source('prices', 'hour') }} as p
            on d.date = p.timestamp
            and d.blockchain = p.blockchain
            and d.contract_address = p.contract_address

)

select
    *
from
    summary
