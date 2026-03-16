{{
    config(
        alias = 'stg_curve_stableswap_ng_pool_created',
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
      and version = 'stableswap_ng'
),

-- Pool address is NOT emitted in the PlainPoolDeployed event, so we recover it from
-- evms.creation_traces: the factory creates the pool contract in the same tx, so
-- c.address (the newly deployed contract) where c."from" = factory = the pool.
pools_created as (
    select
        c.blockchain,
        c.block_time,
        cast(date_trunc('day', c.block_time) as date) as block_date,
        c.block_number,
        c.tx_hash,
        c."from"   as contract_address,
        c.address  as pool
    from {{ source('evms', 'creation_traces') }} as c
    inner join factory_addresses as f
        on c.blockchain = f.blockchain
        and c."from" = f.contract_address
        and c.block_number >= f.min_block_number
    where (c.blockchain, c."from") in (select blockchain, contract_address from factory_addresses)
    {%- if is_incremental() %}
    and cast(date_trunc('day', c.block_time) as date) >= cast(now() - interval '3' day as date)
    {%- endif %}
),

logs as (
    select
        l.blockchain,
        l.contract_address,
        p.pool,
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
    inner join pools_created as p
        on l.tx_hash = p.tx_hash
        and l.blockchain = p.blockchain
        and l.contract_address = p.contract_address
        and l.block_number = p.block_number
    where l.topic0 = 0xd1d60d4611e4091bb2e5f699eeb79136c21ac2305ad609f3de569afc3471eecc
        and (l.blockchain, l.contract_address) in (select blockchain, contract_address from factory_addresses)
),

decoded as (
    select *
    from table(decode_evm_event(
        abi => '{"name":"PlainPoolDeployed","inputs":[{"name":"coins","type":"address[]","indexed":false},{"name":"A","type":"uint256","indexed":false},{"name":"fee","type":"uint256","indexed":false},{"name":"deployer","type":"address","indexed":false}],"anonymous":false,"type":"event"}',
        input => table(logs)
    ))
)

select
    blockchain,
    contract_address,
    'curve'           as protocol,
    'stableswap_ng'   as version,
    block_date,
    block_time,
    block_number,
    tx_hash,
    tx_from,
    pool,
    coins[1]                                    as token0,
    coins[2]                                    as token1,
    if(cardinality(coins) >= 3, coins[3], null) as token2,
    if(cardinality(coins) >= 4, coins[4], null) as token3,
    if(cardinality(coins) >= 5, coins[5], null) as token4,
    if(cardinality(coins) >= 6, coins[6], null) as token5,
    if(cardinality(coins) >= 7, coins[7], null) as token6,
    if(cardinality(coins) >= 8, coins[8], null) as token7,
    coins,
    "A"                                         as a,
    fee,
    deployer
from decoded
