{{
    config(
        alias = 'stg_uniswap_v3_pool_created',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'block_number', 'tx_hash'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}

with

factory_addresses as (
    select
        blockchain,
        contract_address,
        min_block_number
    from {{ ref('dim_dex_factory_addresses') }}
    where protocol = 'uniswap'
      and version = '3'
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
    inner join factory_addresses as f
        on l.blockchain = f.blockchain
        and l.contract_address = f.contract_address
        and l.block_number >= f.min_block_number
    where
        l.topic0 = 0x783cca1c0412dd0d695e784568c96da2e9c22ff989357a2e8b1d9b2b4e6b7118
        and (l.blockchain, l.contract_address) in (select blockchain, contract_address from factory_addresses)
        {%- if is_incremental() %}
        and l.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
),

decoded as (
    select *
    from table(decode_evm_event(
        abi => '{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token0","type":"address"},{"indexed":true,"internalType":"address","name":"token1","type":"address"},{"indexed":true,"internalType":"uint24","name":"fee","type":"uint24"},{"indexed":false,"internalType":"int24","name":"tickSpacing","type":"int24"},{"indexed":false,"internalType":"address","name":"pool","type":"address"}],"name":"PoolCreated","type":"event"}',
        input => table(logs)
    ))
)

select
    blockchain,
    contract_address,
    'uniswap' as protocol,
    '3'        as version,
    block_date,
    block_time,
    block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1,
    fee,
    tickSpacing as tick_spacing
from decoded
