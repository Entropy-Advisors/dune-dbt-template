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
-- Optimization: transfers are filtered to whitelisted tokens per pool and to blocks
-- at or after each pool's creation (min_block_number). This eliminates dust/airdrop noise and pre-pool history.
-- Curve note: pools with 3–8 tokens (tricrypto_ng, stableswap_ng, stableswap_legacy) are fully covered —
-- token2 through token7 are included in the pool_tokens whitelist wherever non-null.
--
-- V4 note: Uniswap V4 pools do not have individual contracts. All V4 liquidity is held in the
-- PoolManager contract (one per chain). We use contract_address (PoolManager) as the pool identifier
-- for V4 so that token transfers to/from the PoolManager are captured. This means V4 balance is
-- tracked at the PoolManager level (aggregate of all V4 pools per chain) — this is intentional.
-- For V2/V3, pool_address is the pool contract itself.

with

pool_tokens as (
    -- Build the whitelisted set of (pool_address, token_address) pairs with min creation block.
    -- Non-Uniswap-V4: pool_address is the pool contract; token0 and token1 are always present.
    --   Curve multi-coin pools (tricrypto_ng, stableswap_ng, stableswap_legacy) also carry
    --   token2–token7 (null-guarded below). Creation block is unique per pool — no aggregation needed.
    -- Uniswap V4: pool_address is the PoolManager (one per chain, holds all V4 liquidity).
    --   Multiple V4 pools can share a token (e.g. two USDC/ETH pools with different fees).
    --   GROUP BY + min(min_block_time) ensures each (blockchain, pool_address, token_address)
    --   pair produces exactly one row — preventing fan-out on the transfer join.
    -- Curve multi-token: token2–token7 branches cover tricrypto_ng (3 coins), stableswap_legacy
    --   (up to 4 coins), and stableswap_ng (up to 8 coins). Each branch filters where token<N>
    --   is not null — protocols with fewer tokens simply produce zero rows for those branches.

    -- token0/token1 for all non-V4 protocols (including all Curve variants)
    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token0                          as token_address,
        min_block_time
    from {{ ref('int_dex_pool_created') }}
    where not (protocol = 'uniswap' and version = '4')

    union all

    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token1                          as token_address,
        min_block_time
    from {{ ref('int_dex_pool_created') }}
    where not (protocol = 'uniswap' and version = '4')

    union all

    -- token0/token1 for Uniswap V4 (pool_address = PoolManager, one per chain).
    -- Multiple V4 pools can share a token (e.g. two USDC/ETH pools with different fees),
    -- so we GROUP BY and take min(min_block_time) to produce exactly one row per
    -- (blockchain, pool_address, token_address) — preventing fan-out on the transfer join.
    select
        blockchain,
        contract_address                as pool_address,
        protocol,
        version,
        token0                          as token_address,
        min(min_block_time)             as min_block_time
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
        min(min_block_time)             as min_block_time
    from {{ ref('int_dex_pool_created') }}
    where protocol = 'uniswap' and version = '4'
    group by 1, 2, 3, 4, 5

    union all

    -- token2: tricrypto_ng (always 3 coins), stableswap_ng (3+ coins), stableswap_legacy (3+ coins)
    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token2                          as token_address,
        min_block_time
    from {{ ref('int_dex_pool_created') }}
    where token2 is not null

    union all

    -- token3: stableswap_ng (4+ coins), stableswap_legacy (4 coins)
    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token3                          as token_address,
        min_block_time
    from {{ ref('int_dex_pool_created') }}
    where token3 is not null

    union all

    -- token4–7: stableswap_ng only (5–8 coins)
    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token4                          as token_address,
        min_block_time
    from {{ ref('int_dex_pool_created') }}
    where token4 is not null

    union all

    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token5                          as token_address,
        min_block_time
    from {{ ref('int_dex_pool_created') }}
    where token5 is not null

    union all

    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token6                          as token_address,
        min_block_time
    from {{ ref('int_dex_pool_created') }}
    where token6 is not null

    union all

    select
        blockchain,
        pool                            as pool_address,
        protocol,
        version,
        token7                          as token_address,
        min_block_time
    from {{ ref('int_dex_pool_created') }}
    where token7 is not null
),

inflows as (
    -- Transfers INTO the pool ("to" = pool address), whitelisted to pool_tokens.
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
        pt.min_block_time,
        t.contract_address          as token_address,
        t.symbol,
        cast(t.amount_raw as double)            as amount_raw,   -- signed: positive for inflow, negated in outflows CTE
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
        and t.block_time        >= pt.min_block_time
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
    -- Transfers OUT OF the pool ("from" = pool address), whitelisted to pool_tokens. Amount is negated.
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
        pt.min_block_time,
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
        and t.block_time        >= pt.min_block_time
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
