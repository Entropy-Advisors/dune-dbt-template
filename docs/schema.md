# Data Schema & Model Inventory

This document tracks the planned and existing dbt models, their purpose, and their current build status.
Use this as a living reference to plan, review, and iterate on the data architecture.

---

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Built and working |
| 🚧 | In progress |
| 📋 | Planned (not yet built) |
| ❓ | Needs review / decision pending |
| ❌ | Deprecated / removed |

---

## Project Structure

```
root/
├── abis/                                   # Contract ABIs for decoding
├── macros/
│   └── dune_dbt_overrides/                 # Core Dune macro overrides (do not modify)
│       ├── get_custom_schema.sql            # Custom schema name generation
│       ├── source.sql                       # Source macro override (sets database='delta_prod')
│       ├── optimize_table.sql              # Post-hook: OPTIMIZE for delta tables
│       └── vacuum_table.sql                # Post-hook: VACUUM for delta tables
├── models/
│   ├── templates/                          # Starter templates (reference only, not production models)
│   ├── utils/                              # Reusable dimension/lookup models
│   │   └── labels/
│   ├── staging/                            # Clean and standardize raw source data (bronze layer)
│   │   ├── core/
│   │   ├── aave/
│   │   ├── chainlink/
│   │   ├── fluid/
│   │   ├── morpho/
│   │   └── uniswap/
│   ├── intermediate/                       # Business logic and cross-protocol joins (silver layer)
│   │   ├── dex/
│   │   ├── lending/
│   │   └── prices/
│   └── marts/                              # Final analytics-ready datasets (gold layer)
│       ├── dex/
│       ├── lending/
│       ├── morpho/
│       └── prices/
├── seeds/                                  # Static reference data (CSVs)
└── tests/                                  # Custom data quality tests
```

---

## Models

### `utils/labels/` — Shared Dimension Tables

Reusable lookup/dimension tables shared across all layers. These enrich downstream models with metadata.

| Model | Alias | Status | Notes |
|-------|-------|--------|-------|
| `dim_addresses.sql` | `dim_addresses` | 📋 | Labelled wallet and contract addresses |
| `dim_contracts.sql` | `dim_contracts` | 📋 | Contract-specific metadata; consider merging with `dim_addresses` |
| `dim_tokens.sql` | `dim_tokens` | 📋 | Token symbols, decimals, address lookups |

> **Open question**: Should `dim_contracts` be merged into `dim_addresses` with a `type` column, or kept separate for clarity?

---

### `staging/` — Bronze Layer

Thin models that clean and standardize raw source data. Minimal logic — rename columns, cast types, filter obviously bad rows. No joins.

#### `staging/core/` — Core Chain Data

| Model | Alias | Materialization | Status | Source Table |
|-------|-------|----------------|--------|--------------|
| `blocks.sql` | `stg_ethereum_blocks` | 📋 | 📋 | `ethereum.blocks` |
| `transactions.sql` | `stg_ethereum_transactions` | 📋 | 📋 | `ethereum.transactions` |
| `traces.sql` | `stg_ethereum_traces` | 📋 | 📋 | `ethereum.traces` |
| `logs.sql` | `stg_ethereum_logs` | 📋 | 📋 | `ethereum.logs` |

#### `staging/aave/` — Aave V3

| Model | Alias | Materialization | Status | Source Table |
|-------|-------|----------------|--------|--------------|
| `aave_v3_reserve_initializations.sql` | `stg_aave_v3_reserve_initializations` | 📋 | 📋 | `aave_v3_ethereum.Pool_evt_ReserveDataUpdated` |
| `aave_v3_reserve_mints.sql` | `stg_aave_v3_reserve_mints` | 📋 | 📋 | `aave_v3_ethereum.*` |
| `aave_v3_reserve_burns.sql` | `stg_aave_v3_reserve_burns` | 📋 | 📋 | `aave_v3_ethereum.*` |
| `aave_v3_deposits.sql` | `stg_aave_v3_deposits` | 📋 | 📋 | `aave_v3_ethereum.Pool_evt_Supply` |
| `aave_v3_withdrawals.sql` | `stg_aave_v3_withdrawals` | 📋 | 📋 | `aave_v3_ethereum.Pool_evt_Withdraw` |
| `aave_v3_borrows.sql` | `stg_aave_v3_borrows` | 📋 | 📋 | `aave_v3_ethereum.Pool_evt_Borrow` |
| `aave_v3_repayments.sql` | `stg_aave_v3_repayments` | 📋 | 📋 | `aave_v3_ethereum.Pool_evt_Repay` |

#### `staging/chainlink/` — Chainlink

| Model | Alias | Materialization | Status | Source Table |
|-------|-------|----------------|--------|--------------|
| `chainlink_price_oracle.sql` | `stg_chainlink_price_oracle` | 📋 | 📋 | `chainlink_ethereum.*` |

#### `staging/fluid/` — Fluid Protocol

| Model | Alias | Materialization | Status | Source Table |
|-------|-------|----------------|--------|--------------|
| `fluid_ftoken_creations.sql` | `stg_fluid_ftoken_creations` | 📋 | 📋 | TBD |
| `fluid_dex_deployments.sql` | `stg_fluid_dex_deployments` | 📋 | 📋 | TBD |
| `fluid_vault_deployments.sql` | `stg_fluid_vault_deployments` | 📋 | 📋 | TBD |
| `fluid_swaps.sql` | `stg_fluid_swaps` | 📋 | 📋 | TBD |
| `fluid_deposits.sql` | `stg_fluid_deposits` | 📋 | 📋 | TBD |
| `fluid_withdrawals.sql` | `stg_fluid_withdrawals` | 📋 | 📋 | TBD |
| `fluid_borrows.sql` | `stg_fluid_borrows` | 📋 | 📋 | TBD |
| `fluid_repayments.sql` | `stg_fluid_repayments` | 📋 | 📋 | TBD |
| `fluid_operates.sql` | `stg_fluid_operates` | 📋 | 📋 | TBD — catch-all operate events |

> **Open question**: What are the exact decoded source tables for Fluid? Need to confirm in Dune data explorer.

#### `staging/morpho/` — Morpho

| Model | Alias | Materialization | Status | Source Table |
|-------|-------|----------------|--------|--------------|
| `morpho_deposits.sql` | `stg_morpho_deposits` | 📋 | 📋 | `morpho_ethereum.*` |
| `morpho_withdrawals.sql` | `stg_morpho_withdrawals` | 📋 | 📋 | `morpho_ethereum.*` |
| `morpho_borrows.sql` | `stg_morpho_borrows` | 📋 | 📋 | `morpho_ethereum.*` |
| `morpho_repayments.sql` | `stg_morpho_repayments` | 📋 | 📋 | `morpho_ethereum.*` |

#### `staging/uniswap/` — Uniswap

| Model | Alias | Materialization | Status | Source Table |
|-------|-------|----------------|--------|--------------|
| `uniswap_v3_factory_pool_created.sql` | `stg_uniswap_v3_factory_pool_created` | 📋 | 📋 | `uniswap_v3_ethereum.Factory_evt_PoolCreated` |
| `uniswap_v3_pool_mint.sql` | `stg_uniswap_v3_pool_mint` | 📋 | 📋 | `uniswap_v3_ethereum.Pair_evt_Mint` |
| `uniswap_v3_pool_burn.sql` | `stg_uniswap_v3_pool_burn` | 📋 | 📋 | `uniswap_v3_ethereum.Pair_evt_Burn` |
| `uniswap_v3_pool_collect.sql` | `stg_uniswap_v3_pool_collect` | 📋 | 📋 | `uniswap_v3_ethereum.Pair_evt_Collect` |
| `uniswap_v3_pool_swap.sql` | `stg_uniswap_v3_pool_swap` | 📋 | 📋 | `uniswap_v3_ethereum.Pair_evt_Swap` |
| `uniswap_v4_pool_manager_initializations.sql` | `stg_uniswap_v4_pool_manager_initializations` | 📋 | 📋 | `uniswap_v4_ethereum.PoolManager_evt_Initialize` |
| `uniswap_v4_pool_manager_swaps.sql` | `stg_uniswap_v4_pool_manager_swaps` | 📋 | 📋 | `uniswap_v4_ethereum.PoolManager_evt_Swap` |

---

### `intermediate/` — Silver Layer

Business logic models that join and transform staging data. These are not directly queried by end users — they feed the marts layer.

#### `intermediate/dex/`

| Model | Alias | Materialization | Status | Upstream Models |
|-------|-------|----------------|--------|----------------|
| `dex_pool_creations.sql` | `int_dex_pool_creations` | 📋 | 📋 | `stg_uniswap_v3_factory_pool_created`, `stg_uniswap_v4_pool_manager_initializations`, `stg_fluid_dex_deployments` |
| `dex_liquidity_changes.sql` | `int_dex_liquidity_changes` | 📋 | 📋 | `stg_uniswap_v3_pool_mint`, `stg_uniswap_v3_pool_burn`, `stg_uniswap_v3_pool_collect`, `stg_fluid_deposits`, `stg_fluid_withdrawals` |
| `dex_swaps.sql` | `int_dex_swaps` | 📋 | 📋 | `stg_uniswap_v3_pool_swap`, `stg_uniswap_v4_pool_manager_swaps`, `stg_fluid_swaps` |

#### `intermediate/lending/`

| Model | Alias | Materialization | Status | Upstream Models |
|-------|-------|----------------|--------|----------------|
| `lending_deposits.sql` | `int_lending_deposits` | 📋 | 📋 | `stg_aave_v3_deposits`, `stg_morpho_deposits`, `stg_fluid_deposits` |
| `lending_withdrawals.sql` | `int_lending_withdrawals` | 📋 | 📋 | `stg_aave_v3_withdrawals`, `stg_morpho_withdrawals`, `stg_fluid_withdrawals` |
| `lending_borrows.sql` | `int_lending_borrows` | 📋 | 📋 | `stg_aave_v3_borrows`, `stg_morpho_borrows`, `stg_fluid_borrows` |
| `lending_repayments.sql` | `int_lending_repayments` | 📋 | 📋 | `stg_aave_v3_repayments`, `stg_morpho_repayments`, `stg_fluid_repayments` |
| `lending_liquidations.sql` | `int_lending_liquidations` | 📋 | 📋 | TBD — source events for each protocol |

#### `intermediate/prices/`

| Model | Alias | Materialization | Status | Upstream Models |
|-------|-------|----------------|--------|----------------|
| `prices_oracles.sql` | `int_prices_oracles` | 📋 | 📋 | `stg_chainlink_price_oracle` |
| `prices_dexs.sql` | `int_prices_dexs` | 📋 | 📋 | `int_dex_swaps` |

---

### `marts/` — Gold Layer

Final analytics-ready tables. These are the models exposed to dashboards, APIs, and end consumers.

#### `marts/dex/`

| Model | Alias | Materialization | Status | Output Table | Upstream Models |
|-------|-------|----------------|--------|-------------|----------------|
| `dim_dex_pools.sql` | `dim_dex_pools` | 📋 | 📋 | `entropy_advisors.dim_dex_pools` | `int_dex_pool_creations`, `dim_tokens` |
| `fact_dex_liquidities.sql` | `fact_dex_liquidities` | 📋 | 📋 | `entropy_advisors.fact_dex_liquidities` | `int_dex_liquidity_changes`, `dim_dex_pools`, `prices` |
| `fact_dex_swaps.sql` | `fact_dex_swaps` | 📋 | 📋 | `entropy_advisors.fact_dex_swaps` | `int_dex_swaps`, `dim_dex_pools`, `prices` |

#### `marts/lending/`

| Model | Alias | Materialization | Status | Output Table | Upstream Models |
|-------|-------|----------------|--------|-------------|----------------|
| `fact_lending_operations.sql` | `fact_lending_operations` | 📋 | 📋 | `entropy_advisors.fact_lending_operations` | `int_lending_deposits`, `int_lending_withdrawals`, `int_lending_borrows`, `int_lending_repayments`, `int_lending_liquidations`, `prices` |

#### `marts/morpho/`

| Model | Alias | Materialization | Status | Output Table | Upstream Models |
|-------|-------|----------------|--------|-------------|----------------|
| `fact_morpho_vaults.sql` | `fact_morpho_vaults` | 📋 | 📋 | `entropy_advisors.fact_morpho_vaults` | `stg_morpho_*`, `prices` |

> **Open question**: Is `fact_morpho_vaults` a Morpho-specific mart, or should Morpho vault logic live under `marts/lending/` and be unified with other lending protocols? If Morpho vaults have unique mechanics (e.g., vault shares, curator roles) it may justify its own mart.

#### `marts/prices/`

| Model | Alias | Materialization | Status | Output Table | Upstream Models |
|-------|-------|----------------|--------|-------------|----------------|
| `prices.sql` | `prices` | 📋 | 📋 | `entropy_advisors.prices` | `int_prices_oracles`, `int_prices_dexs` |

---

## Open Questions & Design Decisions

Track architectural decisions and open questions here. Once resolved, document the decision and rationale.

| # | Question | Status | Decision |
|---|----------|--------|---------|
| 1 | Should `dim_contracts` be merged into `dim_addresses`? | ❓ Open | — |
| 2 | What are the exact Fluid decoded source tables in Dune? | ❓ Open | — |
| 3 | Should Morpho vault logic live in `marts/morpho/` or `marts/lending/`? | ❓ Open | — |
| 4 | Should `fluid_operates` be split into separate deposit/borrow/etc. models, or kept as one? | ❓ Open | — |
| 5 | What is the preferred materialization for staging models — `view` or `incremental`? | ❓ Open | — |
| 6 | Should price models prefer Chainlink oracle prices, DEX-derived prices, or a blended approach? | ❓ Open | — |
| 7 | Do any marts need multi-chain support (e.g., Arbitrum, Base) from the start, or Ethereum-only first? | ❓ Open | — |

---

## Materialization Strategy (Draft)

| Layer | Default Materialization | Rationale |
|-------|------------------------|-----------|
| `utils/` | `view` | Small lookups, always fresh |
| `staging/` | `incremental` (merge) | Large raw event tables, append-mostly |
| `intermediate/` | `incremental` (merge) or `view` | Depends on query cost; default to view, promote to incremental when slow |
| `marts/` | `incremental` (merge) | Production tables, must be performant |

---

## Lineage Overview

```
Sources (Dune delta_prod)
    │
    ▼
staging/           ← Clean raw events per protocol
    │
    ▼
utils/labels/      ← Token/address enrichment (joins in intermediate or marts)
    │
    ▼
intermediate/      ← Cross-protocol unions, business logic
    │
    ▼
marts/             ← Final analytics tables (exposed to dashboards/APIs)
```
