{{
    config(
        alias = 'stg_sushiswap_v2_pool_created',
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
    where protocol = 'sushiswap'
      and version = '2'
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
        l.topic0 = 0x0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9
        and (l.blockchain, l.contract_address) in (select blockchain, contract_address from factory_addresses)
        {%- if is_incremental() %}
        and l.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
),

decoded as (
    select *
    from table(decode_evm_event(
        abi => '{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token0","type":"address"},{"indexed":true,"internalType":"address","name":"token1","type":"address"},{"indexed":false,"internalType":"address","name":"pair","type":"address"},{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"PairCreated","type":"event"}',
        input => table(logs)
    ))
)

select
    blockchain,
    contract_address,
    'sushiswap' as protocol,
    '2'         as version,
    block_date,
    block_time,
    block_number,
    tx_hash,
    tx_from,
    pair        as pool,
    token0,
    token1
from decoded
