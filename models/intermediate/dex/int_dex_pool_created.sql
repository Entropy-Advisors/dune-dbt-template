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

select
    blockchain,
    contract_address,
    protocol,
    version,
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
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
    block_date as pool_creation_block_date,
    block_time as pool_creation_block_time,
    block_number as pool_creation_block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    null                as fee,
    null                as tick_spacing,
    null                as hooks,
    null                as sqrt_price_x96,
    null                as tick
from {{ ref('stg_camelot_v3_pool_created') }}
