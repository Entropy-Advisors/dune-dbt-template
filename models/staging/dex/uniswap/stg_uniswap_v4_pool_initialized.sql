{{
    config(
        alias = 'stg_uniswap_v4_pool_initialized',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'block_number', 'tx_hash'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}

with

pool_manager_addresses as (
    select
        blockchain,
        contract_address,
        min_block_number
    from {{ ref('dim_dex_factory_addresses') }}
    where protocol = 'uniswap'
      and version = '4'
),

logs as (
    select
        l.blockchain,
        l.contract_address,
        l.topic0,
        l.topic1,
        l.topic2,
        l.topic3,
        l.block_time,
        cast(date_trunc('day', l.block_time) as date) as block_date,
        l.block_number,
        l.tx_hash,
        l.tx_from,
        l.data
    from {{ source('evms', 'logs') }} as l
    inner join pool_manager_addresses as p
        on l.blockchain = p.blockchain
        and l.contract_address = p.contract_address
        and l.block_number >= p.min_block_number
    where
        -- Initialize(bytes32,address,address,uint24,int24,address,uint160,int24)
        l.topic0 = 0xdd466e674ea557f56295e2d0218a125ea4b4f0f6f3307b95f85e6110838d6438
        {%- if is_incremental() %}
        and l.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
),

decoded as (
    select *
    from table(decode_evm_event(
        abi => '{"anonymous":false,"inputs":[{"indexed":true,"internalType":"PoolId","name":"id","type":"bytes32"},{"indexed":true,"internalType":"Currency","name":"currency0","type":"address"},{"indexed":true,"internalType":"Currency","name":"currency1","type":"address"},{"indexed":false,"internalType":"uint24","name":"fee","type":"uint24"},{"indexed":false,"internalType":"int24","name":"tickSpacing","type":"int24"},{"indexed":false,"internalType":"IHooks","name":"hooks","type":"address"},{"indexed":false,"internalType":"uint160","name":"sqrtPriceX96","type":"uint160"},{"indexed":false,"internalType":"int24","name":"tick","type":"int24"}],"name":"Initialize","type":"event"}',
        input => table(logs)
    ))
)

select
    blockchain,
    contract_address,
    'uniswap' as protocol,
    '4'        as version,
    block_date,
    block_time,
    block_number,
    tx_hash,
    tx_from,
    id         as pool,        -- PoolId (bytes32) — unique pool key, not a contract address
    currency0  as token0,
    currency1  as token1,
    fee,
    tickSpacing as tick_spacing,
    hooks,                     -- hooks contract; 0x000...000 if no hooks attached
    sqrtPriceX96 as sqrt_price_x96,
    tick
from decoded
