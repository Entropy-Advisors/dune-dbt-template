{{
    config(
        alias = 'int_token_hourly_supply',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'block_date', 'token_address'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}

-- Hourly mint/burn aggregation per token per chain, with running circulating supply.
--
-- Reads the FULL history of stg_token_mint_burn_events on every run so the cumulative
-- window function produces correct results. The staging table is a small filtered subset
-- (mint/burn only, labelled tokens) so this is cheap.
-- Only recent rows are inserted into the target via the WHERE at the bottom.

with all_events as (

    select * from {{ ref('stg_token_mint_burn_events') }}

),

hourly as (

    select
        date_trunc('hour', block_time)          as hour,
        cast(date_trunc('day', block_time) as date) as block_date,
        blockchain,
        token_address,
        symbol,
        name,
        label,
        category,
        sum(case when transfer_type = 'mint' then amount else 0.0 end)  as mint_volume,
        sum(case when transfer_type = 'burn' then amount else 0.0 end)  as burn_volume,
        sum(case when transfer_type = 'mint' then amount else 0.0 end)
            - sum(case when transfer_type = 'burn' then amount else 0.0 end) as net_change,
        avg(price)                              as avg_price_usd

    from all_events
    group by
        date_trunc('hour', block_time),
        cast(date_trunc('day', block_time) as date),
        blockchain,
        token_address,
        symbol,
        name,
        label,
        category

),

with_cumulative as (

    select
        hour,
        block_date,
        blockchain,
        token_address,
        symbol,
        name,
        label,
        category,
        mint_volume,
        burn_volume,
        net_change,
        avg_price_usd,
        sum(net_change) over (
            partition by
                blockchain,
                token_address
            order by hour
            rows between unbounded preceding and current row
        )                                       as circulating_supply

    from hourly

)

select
    hour,
    block_date,
    blockchain,
    token_address,
    symbol,
    name,
    label,
    category,
    mint_volume,
    burn_volume,
    net_change,
    avg_price_usd,
    circulating_supply,
    circulating_supply * avg_price_usd          as market_cap_usd

from with_cumulative

{%- if is_incremental() %}
where block_date >= now() - interval '3' day
{%- endif %}
