{{
    config(
        alias = 'stg_balancer_v3_pool_created',
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
    where protocol = 'balancer' and version = '3'
),

-- PoolRegistered is emitted on the Balancer V3 Vault when a pool is registered.
-- pool (indexed, address) = pool contract address (topic1).
-- factory (indexed, address) = factory that registered the pool (topic2).
-- tokenConfig = (address token, uint8 tokenType, address rateProvider, bool paysYieldFees)[]
-- topic0 = keccak256 of canonical signature with all struct components expanded inline:
--   PoolRegistered(address,address,(address,uint8,address,bool)[],uint256,uint32,
--     (address,address,address),(bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,address),
--     (bool,bool,bool,bool))
--   = 0xbc1561eeab9f40962e2fb827a7ff9c7cdb47a9d7c84caeefa4ed90e043842dad
-- All chains have null min_block_number — guard with IS NULL check.
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
        l.topic0 = 0xbc1561eeab9f40962e2fb827a7ff9c7cdb47a9d7c84caeefa4ed90e043842dad
        and (l.blockchain, l.contract_address) in (select blockchain, contract_address from factory_addresses)
        {%- if is_incremental() %}
        and cast(date_trunc('day', l.block_time) as date) >= cast(now() - interval '3' day as date)
        {%- endif %}
),

decoded as (
    select *
    from table(decode_evm_event(
        abi => '{"anonymous":false,"inputs":[{"indexed":true,"name":"pool","type":"address"},{"indexed":true,"name":"factory","type":"address"},{"indexed":false,"name":"tokenConfig","type":"tuple[]","components":[{"name":"token","type":"address"},{"name":"tokenType","type":"uint8"},{"name":"rateProvider","type":"address"},{"name":"paysYieldFees","type":"bool"}]},{"indexed":false,"name":"swapFeePercentage","type":"uint256"},{"indexed":false,"name":"pauseWindowEndTime","type":"uint32"},{"indexed":false,"name":"roleAccounts","type":"tuple","components":[{"name":"pauseManager","type":"address"},{"name":"swapFeeManager","type":"address"},{"name":"poolCreator","type":"address"}]},{"indexed":false,"name":"hooksConfig","type":"tuple","components":[{"name":"enableHookAdjustedAmounts","type":"bool"},{"name":"shouldCallBeforeInitialize","type":"bool"},{"name":"shouldCallAfterInitialize","type":"bool"},{"name":"shouldCallComputeDynamicSwapFee","type":"bool"},{"name":"shouldCallBeforeSwap","type":"bool"},{"name":"shouldCallAfterSwap","type":"bool"},{"name":"shouldCallBeforeAddLiquidity","type":"bool"},{"name":"shouldCallAfterAddLiquidity","type":"bool"},{"name":"shouldCallBeforeRemoveLiquidity","type":"bool"},{"name":"shouldCallAfterRemoveLiquidity","type":"bool"},{"name":"hooksContract","type":"address"}]},{"indexed":false,"name":"liquidityManagement","type":"tuple","components":[{"name":"disableUnbalancedLiquidity","type":"bool"},{"name":"enableAddLiquidityCustom","type":"bool"},{"name":"enableRemoveLiquidityCustom","type":"bool"},{"name":"enableDonation","type":"bool"}]}],"name":"PoolRegistered","type":"event"}',
        input => table(logs)
    ))
)

select
    blockchain,
    contract_address,
    'balancer'                                                          as protocol,
    '3'                                                                 as version,
    block_date,
    block_time,
    block_number,
    tx_hash,
    tx_from,
    pool,
    factory,
    -- tokenConfig[i].token: Trino row-field access on decoded tuple[] (1-based array)
    tokenConfig[1].token                                                as token0,
    tokenConfig[2].token                                                as token1,
    if(cardinality(tokenConfig) >= 3, tokenConfig[3].token, null)       as token2,
    if(cardinality(tokenConfig) >= 4, tokenConfig[4].token, null)       as token3,
    if(cardinality(tokenConfig) >= 5, tokenConfig[5].token, null)       as token4,
    if(cardinality(tokenConfig) >= 6, tokenConfig[6].token, null)       as token5,
    if(cardinality(tokenConfig) >= 7, tokenConfig[7].token, null)       as token6,
    if(cardinality(tokenConfig) >= 8, tokenConfig[8].token, null)       as token7,
    tokenConfig                                                         as token_config,
    swapFeePercentage                                                   as swap_fee_percentage,
    pauseWindowEndTime                                                  as pause_window_end_time,
    roleAccounts                                                        as role_accounts,
    hooksConfig                                                         as hooks_config,
    liquidityManagement                                                 as liquidity_management
from decoded
