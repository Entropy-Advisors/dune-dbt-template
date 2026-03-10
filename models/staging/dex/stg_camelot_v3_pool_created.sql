{{
    config(
        alias = 'stg_camelot_v3_pool_created',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'block_number', 'tx_hash'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}

-- Camelot V3 uses Algebra Finance V1.9 (directional fees AMM), NOT Uniswap V3.
-- Pool creation event: Pool(address indexed token0, address indexed token1, address pool)
-- topic0: keccak256("Pool(address,address,address)") — verify against on-chain logs if results are unexpected.
-- No fee or tick_spacing — Algebra uses dynamic per-pool fees, not fixed fee tiers.

with

factory_addresses as (
    select
        blockchain,
        contract_address,
        min_block_number
    from {{ ref('dim_dex_factory_addresses') }}
    where protocol = 'camelot'
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
        l.topic0 = 0x91ccaa7a278130b65168c3a0c8d3bcae84cf5e43704342bd3ec0b59e59c036db
        {%- if is_incremental() %}
        and l.block_date >= cast(now() - interval '3' day as date)
        {%- endif %}
),

decoded as (
    select *
    from table(decode_evm_event(
        abi => '{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token0","type":"address"},{"indexed":true,"internalType":"address","name":"token1","type":"address"},{"indexed":false,"internalType":"address","name":"pool","type":"address"}],"name":"Pool","type":"event"}',
        input => table(logs)
    ))
)

select
    blockchain,
    contract_address,
    'camelot' as protocol,
    '3'        as version,
    block_date,
    block_time,
    block_number,
    tx_hash,
    tx_from,
    pool,
    token0,
    token1
from decoded
