{{
    config(
        alias = 'int_dex_pool_daily_net_change',
        materialized = 'view'
    )
}}

-- Daily net token change per (blockchain, pool, token).
-- Sums all inflows and outflows (already signed) for each day.
-- This is a cheap GROUP BY view — no window functions, no cumulative logic.
-- The running balance is computed in fact_dex_pool_daily_token_balance (mart, table).

select
    blockchain,
    block_date                                          as day,
    pool,
    protocol,
    version,
    token_address,
    symbol,
    min_block_time,
    sum(amount)                                         as net_change
from {{ ref('stg_dex_pool_token_transfers') }}
group by 1, 2, 3, 4, 5, 6, 7, 8
