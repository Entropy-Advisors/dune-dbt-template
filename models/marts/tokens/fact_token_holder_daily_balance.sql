{{
    config(
        alias = 'fact_token_holder_daily_balance',
        materialized = 'table'
    )
}}

-- Daily token balance per (blockchain, contract_address, wallet_address).
-- Built from a days spine cross-joined with all observed (wallet, token) pairs,
-- left-joined to daily net changes, then accumulated with a running sum.
--
-- Rows where balance <= 0 are excluded — wallets that have fully exited or rounding artefacts.
--
-- Materialized as a table because the days spine cross-join and cumulative window function
-- are too expensive to recompute on every query.

with

-- Distinct (wallet, token) combinations and their earliest observed transfer.
-- min_block_time computed across all days to anchor the spine per wallet.
wallet_tokens as (
    select distinct
        blockchain,
        contract_address,
        wallet_address,
        symbol,
        category,
        min_block_time
    from {{ ref('int_token_holder_daily_net_change') }}
),

-- Gap-filled calendar: one row per (wallet, token, day) from first transfer to today.
index as (
    select
        cast(d.timestamp as date)                as day,
        wt.blockchain,
        wt.contract_address,
        wt.wallet_address,
        wt.symbol,
        wt.category,
        wt.min_block_time
    from {{ source('utils', 'days') }} as d
    cross join wallet_tokens as wt
    where d.timestamp >= cast(date_trunc('day', wt.min_block_time) as date)
),

with_index as (
    select
        i.day,
        i.blockchain,
        i.contract_address,
        i.wallet_address,
        i.symbol,
        i.category,
        i.min_block_time,
        d.net_change,
        -- Running cumulative balance. NULL gaps treated as 0 (no change that day).
        sum(coalesce(d.net_change, 0)) over (
            partition by i.blockchain, i.contract_address, i.wallet_address
            order by i.day
        )                                        as balance
    from index as i
    left join {{ ref('int_token_holder_daily_net_change') }} as d
        on  i.day              = d.day
        and i.blockchain       = d.blockchain
        and i.contract_address = d.contract_address
        and i.wallet_address   = d.wallet_address
)

select *
from with_index
where balance > 0