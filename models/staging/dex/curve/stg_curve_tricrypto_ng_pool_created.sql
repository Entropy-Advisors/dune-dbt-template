{{
    config(
        alias = 'stg_curve_tricrypto_ng_pool_created',
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
    where protocol = 'curve'
      and version = 'tricrypto_ng'
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
        l.topic0 = 0xa307f5d0802489baddec443058a63ce115756de9020e2b07d3e2cd2f21269e2a
        and (l.blockchain, l.contract_address) in (select blockchain, contract_address from factory_addresses)
        {%- if is_incremental() %}
        and l.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
),

decoded as (
    select *
    from table(decode_evm_event(
        abi => '{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"pool","type":"address"},{"indexed":false,"internalType":"string","name":"name","type":"string"},{"indexed":false,"internalType":"string","name":"symbol","type":"string"},{"indexed":false,"internalType":"address","name":"weth","type":"address"},{"indexed":false,"internalType":"address[3]","name":"coins","type":"address[3]"},{"indexed":false,"internalType":"address","name":"math","type":"address"},{"indexed":false,"internalType":"bytes32","name":"salt","type":"bytes32"},{"indexed":false,"internalType":"uint256","name":"packed_precisions","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"packed_A_gamma","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"packed_fee_params","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"packed_rebalancing_params","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"packed_prices","type":"uint256"},{"indexed":false,"internalType":"address","name":"deployer","type":"address"}],"name":"TricryptoPoolDeployed","type":"event"}',
        input => table(logs)
    ))
)

select
    blockchain,
    contract_address,
    'curve'          as protocol,
    'tricrypto_ng'   as version,
    block_date,
    block_time,
    block_number,
    tx_hash,
    tx_from,
    pool,
    coins[1]         as token0,
    coins[2]         as token1,
    coins[3]         as token2,
    coins,
    weth,
    name,
    symbol,
    math,
    salt,
    packed_precisions,
    packed_A_gamma   as packed_a_gamma,
    packed_fee_params,
    packed_rebalancing_params,
    packed_prices,
    deployer
from decoded
