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
-- at or after each pool's creation (min_block_time). This eliminates dust/airdrop noise and pre-pool history.
-- Curve multi-token pools (up to 8 coins) and Uniswap V4 (PoolManager-level tracking) are handled
-- in the pool_tokens CTE via UNNEST — no per-protocol branches required.

with

pool_tokens as (
    -- Build the whitelisted set of (pool_address, token_address) pairs with min creation block.
    -- UNNEST pivots all 8 token slots in one pass — one read of int_dex_pool_created vs 10.
    -- Non-V4: pool_address = pool contract. V4: pool_address = PoolManager (one per chain).
    -- GROUP BY + min(min_block_time) collapses V4 fan-out (multiple pools sharing a token).
    -- Curve multi-token pools (up to 8 coins) are covered automatically — null slots are filtered.
    select
        blockchain,
        case
            when protocol = 'uniswap' and version = '4' then contract_address
            else pool
        end                             as pool_address,
        protocol,
        version,
        tok                             as token_address,
        min(min_block_time)             as min_block_time
    from {{ ref('int_dex_pool_created') }}
    cross join unnest(array[token0, token1, token2, token3, token4, token5, token6, token7]) as t(tok)
    where tok is not null
    group by 1, 2, 3, 4, 5
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
