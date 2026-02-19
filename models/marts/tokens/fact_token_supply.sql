{{
    config(
        alias = 'fact_token_supply',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['hour', 'token_address'],
        properties = {
            "partitioned_by": "ARRAY['block_date']"
        }
    )
}}

-- Cross-chain pivot of int_token_hourly_supply.
-- One row per (hour, token) with per-chain and total supply/market cap columns.
-- Chains: ethereum, base, arbitrum, plasma.
--
-- avg_price_usd: coalesced from chains in order of liquidity depth.
-- total_market_cap_usd: total_circulating_supply × single coalesced price.

with hourly_supply as (

    select * from {{ ref('int_token_hourly_supply') }}

)

select
    hour,
    cast(date_trunc('day', hour) as date)           as block_date,
    token_address,
    symbol,
    name,
    label,
    category,

    -- Circulating supply per chain
    sum(case when blockchain = 'ethereum' then circulating_supply else 0.0 end)     as ethereum_circulating_supply,
    sum(case when blockchain = 'base'     then circulating_supply else 0.0 end)     as base_circulating_supply,
    sum(case when blockchain = 'arbitrum' then circulating_supply else 0.0 end)     as arbitrum_circulating_supply,
    sum(case when blockchain = 'plasma'   then circulating_supply else 0.0 end)     as plasma_circulating_supply,
    sum(circulating_supply)                                                          as total_circulating_supply,

    -- Mint volume per chain
    sum(case when blockchain = 'ethereum' then mint_volume else 0.0 end)            as ethereum_mint_volume,
    sum(case when blockchain = 'base'     then mint_volume else 0.0 end)            as base_mint_volume,
    sum(case when blockchain = 'arbitrum' then mint_volume else 0.0 end)            as arbitrum_mint_volume,
    sum(case when blockchain = 'plasma'   then mint_volume else 0.0 end)            as plasma_mint_volume,

    -- Burn volume per chain
    sum(case when blockchain = 'ethereum' then burn_volume else 0.0 end)            as ethereum_burn_volume,
    sum(case when blockchain = 'base'     then burn_volume else 0.0 end)            as base_burn_volume,
    sum(case when blockchain = 'arbitrum' then burn_volume else 0.0 end)            as arbitrum_burn_volume,
    sum(case when blockchain = 'plasma'   then burn_volume else 0.0 end)            as plasma_burn_volume,

    -- Single representative price (most liquid chain first)
    coalesce(
        max(case when blockchain = 'ethereum' then avg_price_usd end),
        max(case when blockchain = 'base'     then avg_price_usd end),
        max(case when blockchain = 'arbitrum' then avg_price_usd end),
        max(case when blockchain = 'plasma'   then avg_price_usd end)
    )                                                                                as avg_price_usd,

    -- Market cap per chain
    sum(case when blockchain = 'ethereum' then market_cap_usd else 0.0 end)         as ethereum_market_cap_usd,
    sum(case when blockchain = 'base'     then market_cap_usd else 0.0 end)         as base_market_cap_usd,
    sum(case when blockchain = 'arbitrum' then market_cap_usd else 0.0 end)         as arbitrum_market_cap_usd,
    sum(case when blockchain = 'plasma'   then market_cap_usd else 0.0 end)         as plasma_market_cap_usd,

    -- Total market cap: total supply × single coalesced price
    sum(circulating_supply) * coalesce(
        max(case when blockchain = 'ethereum' then avg_price_usd end),
        max(case when blockchain = 'base'     then avg_price_usd end),
        max(case when blockchain = 'arbitrum' then avg_price_usd end),
        max(case when blockchain = 'plasma'   then avg_price_usd end)
    )                                                                                as total_market_cap_usd

from hourly_supply

{%- if is_incremental() %}
where block_date >= now() - interval '3' day
{%- endif %}

group by
    hour,
    token_address,
    symbol,
    name,
    label,
    category
