{{
    config(
        alias = 'int_token_holder_daily_net_change',
        materialized = 'view'
    )
}}

-- Daily net transfer amount per (blockchain, contract_address, wallet_address).
-- No spine, no gap-fill, no window functions — those are handled in fact_token_holder_daily_balance.
--
-- Fed by: stg_token_holder_transfers.
-- Feeds:  fact_token_holder_daily_balance.
--
-- min_block_time passes through from dim_labels (token deployment timestamp, constant per contract).
-- Used by fact_token_holder_daily_balance to anchor the days spine per (wallet, token).
--
-- Cheap GROUP BY view — mirrors the DEX pattern (int_dex_pool_daily_net_change).
-- The daily spine, gap-fill, and cumulative columns are owned by fact_token_holder_daily_balance.

select
    cast(date_trunc('day', block_time) as date)  as day,
    blockchain,
    contract_address,
    wallet_address,
    symbol,
    category,
    min_block_time,
    sum(amount)                                  as net_change
from {{ ref('stg_token_holder_transfers') }}
group by 1, 2, 3, 4, 5, 6, 7