{{
    config(
        alias = 'int_dex_pool_created',
        materialized = 'view'
    )
}}

-- Union of all DEX pool creation events across protocols and versions.
-- V2-style protocols have no fee or tick_spacing (NULL).
-- Camelot V3 uses Algebra dynamic fees — no fixed fee or tick_spacing (NULL).
-- V4 has additional columns: hooks, sqrt_price_x96, tick.
--   V4 pool = PoolId (bytes32), not a pool contract address.
--   V4 contract_address = PoolManager (one per chain, not a factory).
-- Balancer V2: fee = NULL (fee is per-pool, not in the creation event); token2-token7 cardinality-guarded.
-- Balancer V3: fee = swapFeePercentage (uint256, 18-decimal fixed point); token2-token7 cardinality-guarded.
-- token2-token7: NULL for 2-token protocols; token2 only for tricrypto_ng (always 3 coins);
--   token2-token3 for stableswap_legacy (up to 4 coins); token2-token7 for stableswap_ng and Balancer V2/V3 (up to 8 tokens).

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_uniswap_v2_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    fee,
    tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_uniswap_v3_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    fee,
    tick_spacing,
    hooks,
    sqrt_price_x96,
    tick
from {{ ref('stg_uniswap_v4_pool_initialized') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_sushiswap_v2_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    fee,
    tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_sushiswap_v3_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_pancakeswap_v2_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    fee,
    tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_pancakeswap_v3_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_gammaswap_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_camelot_v2_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as min_block_date,
    block_time as min_block_time,
    block_number as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_camelot_v3_pool_created') }}

union all

select
    blockchain,
    contract_address,
    'curve'             as protocol,
    'twocrypto_ng'      as version,
    block_date          as min_block_date,
    block_time          as min_block_time,
    block_number        as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_curve_twocrypto_ng_pool_created') }}

union all

select
    blockchain,
    contract_address,
    'curve'             as protocol,
    'tricrypto_ng'      as version,
    block_date          as min_block_date,
    block_time          as min_block_time,
    block_number        as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    token2,
    null                as token3,
    null                as token4,
    null                as token5,
    null                as token6,
    null                as token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_curve_tricrypto_ng_pool_created') }}

union all

select
    blockchain,
    contract_address,
    'curve'             as protocol,
    'stableswap_ng'     as version,
    block_date          as min_block_date,
    block_time          as min_block_time,
    block_number        as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    token2,
    token3,
    token4,
    token5,
    token6,
    token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_curve_stableswap_ng_pool_created') }}

union all

select
    blockchain,
    contract_address,
    'curve'               as protocol,
    'stableswap_legacy'   as version,
    block_date            as min_block_date,
    block_time            as min_block_time,
    block_number          as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    token2,
    token3,
    null                  as token4,
    null                  as token5,
    null                  as token6,
    null                  as token7,
    null                  as fee,
    null                  as tick_spacing,
    null                  as hooks,
    null                  as sqrt_price_x96,
    null                  as tick
from {{ ref('stg_curve_stableswap_legacy_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date          as min_block_date,
    block_time          as min_block_time,
    block_number        as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    token2,
    token3,
    token4,
    token5,
    token6,
    token7,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_balancer_v2_pool_created') }}

union all

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date          as min_block_date,
    block_time          as min_block_time,
    block_number        as min_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    token2,
    token3,
    token4,
    token5,
    token6,
    token7,
    swap_fee_percentage as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_balancer_v3_pool_created') }}
