{{
    config(
        alias = 'stg_balancer_v2_pool_created',
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
    select blockchain, contract_address, min_block_number
    from {{ ref('dim_dex_factory_addresses') }}
    where protocol = 'balancer' and version = '2'
),

-- TokensRegistered is emitted on the Balancer V2 Vault when a pool registers its tokens.
-- The poolId is bytes32 where the first 20 bytes = pool contract address (Balancer V2 encoding).
-- topic0 = keccak256("TokensRegistered(bytes32,address[],address[])")
--        = 0xf5847d3f2197b16cdcd2098ec95d0905cd1abdaf415f07bb7cef2bba8ac5dec4
-- One Vault address is reused across all supported chains.
-- Some chains have null min_block_number — guard with IS NULL check.
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
        on  l.blockchain       = f.blockchain
        and l.contract_address = f.contract_address
        and (f.min_block_number is null or l.block_number >= f.min_block_number)
    where
        l.topic0 = 0xf5847d3f2197b16cdcd2098ec95d0905cd1abdaf415f07bb7cef2bba8ac5dec4
        and (l.blockchain, l.contract_address) in (select blockchain, contract_address from factory_addresses)
        {%- if is_incremental() %}
        and cast(date_trunc('day', l.block_time) as date) >= cast(now() - interval '3' day as date)
        {%- endif %}
),

decoded as (
    select *
    from table(decode_evm_event(
        abi => '{"anonymous":false,"inputs":[{"indexed":true,"name":"poolId","type":"bytes32"},{"indexed":false,"name":"tokens","type":"address[]"},{"indexed":false,"name":"assetManagers","type":"address[]"}],"name":"TokensRegistered","type":"event"}',
        input => table(logs)
    ))
)

select
    blockchain,
    contract_address,
    'balancer'                                                   as protocol,
    '2'                                                          as version,
    block_date,
    block_time,
    block_number,
    tx_hash,
    tx_from,
    -- Pool address = first 20 bytes of poolId (Balancer V2 poolId encoding)
    cast(substr(poolId, 1, 20) as varbinary)                     as pool,
    poolId                                                       as pool_id,
    tokens[1]                                                    as token0,
    tokens[2]                                                    as token1,
    if(cardinality(tokens) >= 3, tokens[3], null)                as token2,
    if(cardinality(tokens) >= 4, tokens[4], null)                as token3,
    if(cardinality(tokens) >= 5, tokens[5], null)                as token4,
    if(cardinality(tokens) >= 6, tokens[6], null)                as token5,
    if(cardinality(tokens) >= 7, tokens[7], null)                as token6,
    if(cardinality(tokens) >= 8, tokens[8], null)                as token7,
    tokens,
    assetManagers                                                as asset_managers
from decoded
