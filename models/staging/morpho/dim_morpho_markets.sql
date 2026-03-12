{{ config(
    alias = 'dim_morpho_markets'
    , materialized = 'view'
) }}

select
    chain as blockchain
    , contract_address
    , evt_tx_hash
    , evt_tx_from
    , evt_tx_to
    , evt_block_time
    , evt_block_number
    , evt_block_date
    , id
    , from_hex(json_value(marketParams, 'lax $.loanToken')) as borrow_token
    , from_hex(json_value(marketParams, 'lax $.collateralToken')) as collateral_token
    , from_hex(json_value(marketParams, 'lax $.oracle')) as oracle
    , from_hex(json_value(marketParams, 'lax $.irm')) as irm_address
    , cast(json_value(marketParams, 'lax $.lltv') as double) / 1e18 as ltv
from
    {{ source('morpho_blue_multichain', 'morphoblue_evt_createmarket') }}
