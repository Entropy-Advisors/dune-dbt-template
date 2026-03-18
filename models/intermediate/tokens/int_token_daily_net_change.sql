{{
    config(
        alias = 'int_token_daily_net_change',
        materialized = 'view'
    )
}}

-- Daily mint/burn volumes and net change per token per chain.
-- Signed amounts from staging: positive = mint, negative = burn.
-- burn_volume negates the (already negative) burn amounts to produce a positive volume figure.
--
-- Fed by: stg_token_mint_burn_events.
-- Feeds:  fact_token_daily_supply.
--
-- No spine, no gap-fill, no window functions — those are handled in fact_token_daily_supply.
-- This model is a cheap GROUP BY view; the mart owns the expensive daily spine and cumulative logic.

select
    cast(date_trunc('day', block_time) as date)                         as day,
    blockchain,
    contract_address,
    symbol,
    category,
    sum(case when event_type = 'mint' then  amount else 0.0 end)       as mint_volume,
    sum(case when event_type = 'burn' then -amount else 0.0 end)       as burn_volume,
    sum(amount)                                                          as net_change
from {{ ref('stg_token_mint_burn_events') }}
group by 1, 2, 3, 4, 5
