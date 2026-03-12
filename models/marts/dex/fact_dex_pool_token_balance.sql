{{
    config(
        alias = 'fact_dex_pool_token_balance',
        materialized = 'table'
    )
}}

-- Daily token balance per (blockchain, pool, token).
-- Built from a days spine cross-joined with all observed (pool, token) pairs,
-- left-joined to daily net changes, then accumulated with a running sum.
--
-- Rows where balance = 0 or below are excluded — these represent pools that have been
-- fully drained or are net-negative due to rounding/accounting artefacts.
--
-- Materialized as a table because the days spine cross-join and cumulative window function
-- are too expensive to recompute on every query.

with

-- Distinct (blockchain, pool, token) combinations and their earliest observed day.
-- Used to anchor the days spine per entity — avoids generating rows before any transfers existed.
pool_tokens as (
    select distinct
        blockchain,
        pool,
        protocol,
        version,
        token_address,
        symbol,
        pool_creation_block_time
    from {{ ref('int_dex_pool_daily_net_change') }}
),

-- Gap-filled calendar: one row per (pool, token, day) from first transfer to today.
index as (
    select
        d.timestamp                 as day,
        pt.blockchain,
        pt.pool,
        pt.protocol,
        pt.version,
        pt.token_address,
        pt.symbol
    from {{ source('utils', 'days') }} as d
    cross join pool_tokens as pt
    where d.timestamp >= pt.pool_creation_block_time
),

-- Join net changes onto the gap-filled index (NULL for days with no transfers).
daily_net_change as (
    select
    day,
    blockchain,
    pool,
    protocol,
    version,
    token_address,
    symbol,
    sum(net_change)                 as net_change
    -- sum(net_change_usd)          as net_change_usd  -- uncomment to include USD balance
    from {{ ref('int_dex_pool_daily_net_change') }}
    group by 1, 2, 3, 4, 5, 6, 7
),

with_index as (
    select
        index.day,
        index.blockchain,
        index.pool,
        index.protocol,
        index.version,
        index.token_address,
        index.symbol,
        daily_net_change.net_change,
        -- Running cumulative balance. NULL gaps treated as 0 (no change that day).
        sum(coalesce(daily_net_change.net_change, 0)) over (
            partition by index.blockchain, index.pool, index.token_address
            order by index.day
        )                           as balance
    from index
    left join daily_net_change
        on  index.day           = daily_net_change.day
        and index.blockchain    = daily_net_change.blockchain
        and index.pool          = daily_net_change.pool
        and index.token_address = daily_net_change.token_address
)

select *
from with_index
where balance > 0
