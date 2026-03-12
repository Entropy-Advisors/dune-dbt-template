{{
    config(
        alias = 'stg_dex_pool_token_transfers',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'block_number', 'tx_hash', 'evt_index', 'event_type'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}

-- Token transfer events (ERC20 + native) to and from tracked DEX pool contracts.
-- Each row is a single token transfer classified as 'inflow' (token entering the pool)
-- or 'outflow' (token leaving the pool). Amount is signed: positive for inflow, negative for outflow.
-- Amounts are summed downstream to compute daily net change and running balance.
--
-- price_usd and amount_usd are captured at transfer time for future TVL use — not used in balance models.
--
-- Optimization: transfers are filtered to token0/token1 per pool (token whitelist) and to blocks
-- at or after each pool's creation (pool_creation_block_number). This eliminates dust/airdrop noise and pre-pool history.
--
-- V4 note: Uniswap V4 pools do not have individual contracts. All V4 liquidity is held in the
-- PoolManager contract (one per chain). We use contract_address (PoolManager) as the pool identifier
-- for V4 so that token transfers to/from the PoolManager are captured. This means V4 balance is
-- tracked at the PoolManager level (aggregate of all V4 pools per chain) — this is intentional.
-- For V2/V3, pool_address is the pool contract itself.

with

pool_tokens as (
    -- Build the whitelisted set of (pool_address, token_address) pairs with min creation block.
    -- Non-Uniswap-V4: pool_address is the pool contract; each pool has exactly token0 and token1.
    --   Creation block is unique per pool — no aggregation needed.
    -- Uniswap V4: pool_address is the PoolManager (one per chain, holds all V4 liquidity).
    --   Multiple V4 pools can share a token (e.g. two USDC/ETH pools with different fees).
    --   We aggregate to min(pool_creation_block_number) to ensure each (pool_address, token_address)
    --   pair produces exactly one row — preventing duplicate join matches on tokens.transfers.
    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token0                          as token_address,
        pool_creation_block_time
    from {{ ref('int_dex_pool_created') }}
    where not (protocol = 'uniswap' and version = '4')

    union all

    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token1                          as token_address,
        pool_creation_block_time
    from {{ ref('int_dex_pool_created') }}
    where not (protocol = 'uniswap' and version = '4')

    union all

    select
        blockchain,
        contract_address                as pool_address,
        protocol,
        version,
        token0                          as token_address,
        min(pool_creation_block_time)   as pool_creation_block_time
    from {{ ref('int_dex_pool_created') }}
    where protocol = 'uniswap' and version = '4'
    group by 1, 2, 3, 4, 5

    union all

    select
        blockchain,
        contract_address                as pool_address,
        protocol,
        version,
        token1                          as token_address,
        min(pool_creation_block_time)   as pool_creation_block_time
    from {{ ref('int_dex_pool_created') }}
    where protocol = 'uniswap' and version = '4'
    group by 1, 2, 3, 4, 5
),

inflows as (
    -- Transfers INTO the pool ("to" = pool address), whitelisted to token0/token1 only.
    select
        t.blockchain,
        t.block_date,
        t.block_time,
        t.block_number,
        t.tx_hash,
        t.evt_index,
        'inflow'                    as event_type,
        pt.pool_address             as pool,
        pt.protocol,
        pt.version,
        pt.pool_creation_block_time,
        t.contract_address          as token_address,
        t.symbol,
        cast(t.amount_raw as double)            as amount_raw,
        cast(t.amount as double)                as amount,
        t.price_usd,
        cast(t.amount_usd as double)            as amount_usd,
        t."from"                    as from_address,
        t."to"                      as to_address
    from {{ source('tokens', 'transfers') }} as t
    inner join pool_tokens as pt
        on  t.blockchain        = pt.blockchain
        and t."to"              = pt.pool_address
        and t.contract_address  = pt.token_address
        and t.block_time        >= pt.pool_creation_block_time
    where
        t.token_standard in ('erc20', 'native')
        {%- if is_incremental() %}
        and t.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
        {%- if var('target_blockchain', '') != '' %}
        and t.blockchain = '{{ var("target_blockchain", "") }}'
        {%- endif %}
),

outflows as (
    -- Transfers OUT OF the pool ("from" = pool address), whitelisted to token0/token1 only. Amount is negated.
    select
        t.blockchain,
        t.block_date,
        t.block_time,
        t.block_number,
        t.tx_hash,
        t.evt_index,
        'outflow'                   as event_type,
        pt.pool_address             as pool,
        pt.protocol,
        pt.version,
        pt.pool_creation_block_time,
        t.contract_address          as token_address,
        t.symbol,
        -cast(t.amount_raw as double)           as amount_raw,
        -cast(t.amount as double)               as amount,
        t.price_usd,
        -cast(t.amount_usd as double)           as amount_usd,
        t."from"                    as from_address,
        t."to"                      as to_address
    from {{ source('tokens', 'transfers') }} as t
    inner join pool_tokens as pt
        on  t.blockchain        = pt.blockchain
        and t."from"            = pt.pool_address
        and t.contract_address  = pt.token_address
        and t.block_time        >= pt.pool_creation_block_time
    where
        t.token_standard in ('erc20', 'native')
        {%- if is_incremental() %}
        and t.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
        {%- if var('target_blockchain', '') != '' %}
        and t.blockchain = '{{ var("target_blockchain", "") }}'
        {%- endif %}
)

select * from inflows
union all
select * from outflows
