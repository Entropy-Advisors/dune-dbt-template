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
│   │   ├── dex/
│   │   │   └── dim_dex_factory_addresses.sql   # ✅ DEX factory address registry (inline VALUES)
│   │   └── tokens/
│   │       └── dim_labels.sql                  # ✅ Manual address labels, categories, and types
│   ├── staging/                            # Clean and standardize raw source data (bronze layer)
│   │   ├── dex/                                # ✅ DEX pool creation and token transfer staging
│   │   │   ├── camelot/
│   │   │   ├── curve/
│   │   │   ├── gammaswap/
│   │   │   ├── pancakeswap/
│   │   │   ├── sushiswap/
│   │   │   ├── uniswap/
│   │   │   └── stg_dex_pool_token_transfers.sql
│   │   ├── tokens/                             # ✅ Token mint/burn and holder transfer staging
│   │   │   ├── stg_token_mint_burn_events.sql
│   │   │   └── stg_token_holder_transfers.sql
│   │   ├── core/                               # 📋 Planned
│   │   ├── aave/                               # 📋 Planned
│   │   ├── chainlink/                          # 📋 Planned
│   │   ├── fluid/                              # 📋 Planned
│   │   └── morpho/                             # 📋 Planned
│   ├── intermediate/                       # Business logic and cross-protocol joins (silver layer)
│   │   ├── dex/                                # ✅ Pool creation union + daily net change
│   │   ├── tokens/                             # ✅ Daily mint/burn aggregation
│   │   ├── lending/                            # 📋 Planned
│   │   └── prices/                             # 📋 Planned
│   └── marts/                              # Final analytics-ready datasets (gold layer)
│       ├── dex/                                # ✅ Daily pool token balances
│       ├── tokens/                             # ✅ Daily circulating supply
│       ├── lending/                            # 📋 Planned
│       ├── morpho/                             # 📋 Planned
│       └── prices/                             # 📋 Planned
└── tests/                                  # Custom data quality tests
```

---

## Models

### `utils/dex/` — DEX Dimension Tables

| Model | Alias | Materialization | Status | Notes |
|-------|-------|----------------|--------|-------|
| `dim_dex_factory_addresses.sql` | `dim_dex_factory_addresses` | `view` | ✅ | Inline `VALUES()` registry of all tracked DEX factory contracts. Drives pool creation staging — only events from listed factories are decoded. |

> To add a factory address: edit the inline `VALUES()` in `dim_dex_factory_addresses.sql` and run the relevant job in `jobs/`. See CLAUDE.md → "Updating Factory Addresses".

---

### `utils/tokens/` — Token Dimension Tables

Manual labels and categorizations maintained by Entropy. Used as the whitelist and enrichment source across all layers — filter by `type` and/or `category` to scope downstream queries.

| Model | Alias | Materialization | Status | Notes |
|-------|-------|----------------|--------|-------|
| `dim_labels.sql` | `dim_labels` | `view` | ✅ | Manual address labels. Columns: `blockchain`, `creator`, `address`, `name`, `label`, `type`, `category` |

**Schema:**

| Column | Type | Description |
|--------|------|-------------|
| `blockchain` | varchar | Chain name, lowercase |
| `creator` | varchar | Label author (e.g. `entropy`) |
| `address` | varbinary | Contract or wallet address |
| `name` | varchar | Display name — mixed case allowed (e.g. `USDai`, `sUSDai`) |
| `label` | varchar | Protocol/issuer, lowercase (e.g. `usdai`, `superstate`, `centrifuge`) |
| `type` | varchar | Entity type, lowercase (e.g. `token`) |
| `category` | varchar | Asset category, lowercase (e.g. `stablecoin`, `yield-bearing-stablecoin`, `rwa`) |

> To add a token: append a row to `dim_labels.sql` with `type = 'token'`. No other files need changing.

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

---

## DEX Liquidity Pipeline

Models that track the daily token balance held by DEX pools across all tracked protocols and chains.

### Architecture

Pool creation events from factory contracts are decoded per-protocol in staging, unified into a cross-protocol pool registry (`int_dex_pool_created`), then used to whitelist and classify token transfers into the pool. Signed inflow/outflow amounts are aggregated daily, then accumulated into a running balance per (pool, token, chain).

### Protocols

| Protocol | Versions | Pool Type | Notes |
|----------|----------|-----------|-------|
| Uniswap | v2, v3, v4 | 2-token | V4: pool = PoolId (bytes32); all liquidity held in PoolManager — balance tracked at PoolManager level per chain |
| SushiSwap | v2, v3 | 2-token | |
| PancakeSwap | v2, v3 | 2-token | |
| Camelot | v2, v3 | 2-token | V3 uses Algebra AMM — no fixed fee or tick_spacing |
| GammaSwap | v1 | 2-token | |
| Curve | twocrypto_ng, tricrypto_ng, stableswap_ng, stableswap_legacy | 2–8 tokens | Multi-token pools covered via token0–token7 columns |
| Balancer | v2, v3 | 2–8 tokens | V2: pool = first 20 bytes of poolId; V3: pool emitted as indexed topic; fee = swapFeePercentage |

### Model Inventory

| Layer | Model | Alias | Materialization | Status | Notes |
|-------|-------|-------|----------------|--------|-------|
| Utils | `utils/dex/dim_dex_factory_addresses.sql` | `dim_dex_factory_addresses` | `view` | ✅ | Inline `VALUES()` of tracked factory contracts |
| Staging | `staging/dex/uniswap/stg_uniswap_v2_pool_created.sql` | `stg_uniswap_v2_pool_created` | `incremental` | ✅ | |
| Staging | `staging/dex/uniswap/stg_uniswap_v3_pool_created.sql` | `stg_uniswap_v3_pool_created` | `incremental` | ✅ | Includes `fee`, `tick_spacing` |
| Staging | `staging/dex/uniswap/stg_uniswap_v4_pool_initialized.sql` | `stg_uniswap_v4_pool_initialized` | `incremental` | ✅ | Event: `Initialize`; also captures `hooks`, `sqrt_price_x96`, `tick` |
| Staging | `staging/dex/sushiswap/stg_sushiswap_v2_pool_created.sql` | `stg_sushiswap_v2_pool_created` | `incremental` | ✅ | |
| Staging | `staging/dex/sushiswap/stg_sushiswap_v3_pool_created.sql` | `stg_sushiswap_v3_pool_created` | `incremental` | ✅ | |
| Staging | `staging/dex/pancakeswap/stg_pancakeswap_v2_pool_created.sql` | `stg_pancakeswap_v2_pool_created` | `incremental` | ✅ | |
| Staging | `staging/dex/pancakeswap/stg_pancakeswap_v3_pool_created.sql` | `stg_pancakeswap_v3_pool_created` | `incremental` | ✅ | |
| Staging | `staging/dex/camelot/stg_camelot_v2_pool_created.sql` | `stg_camelot_v2_pool_created` | `incremental` | ✅ | |
| Staging | `staging/dex/camelot/stg_camelot_v3_pool_created.sql` | `stg_camelot_v3_pool_created` | `incremental` | ✅ | Algebra AMM — `fee` and `tick_spacing` NULL |
| Staging | `staging/dex/gammaswap/stg_gammaswap_pool_created.sql` | `stg_gammaswap_pool_created` | `incremental` | ✅ | |
| Staging | `staging/dex/curve/stg_curve_twocrypto_ng_pool_created.sql` | `stg_curve_twocrypto_ng_pool_created` | `incremental` | ✅ | 2 tokens (token0, token1) |
| Staging | `staging/dex/curve/stg_curve_tricrypto_ng_pool_created.sql` | `stg_curve_tricrypto_ng_pool_created` | `incremental` | ✅ | 3 tokens (token0–token2) |
| Staging | `staging/dex/curve/stg_curve_stableswap_ng_pool_created.sql` | `stg_curve_stableswap_ng_pool_created` | `incremental` | ✅ | Up to 8 tokens (token0–token7) |
| Staging | `staging/dex/curve/stg_curve_stableswap_legacy_pool_created.sql` | `stg_curve_stableswap_legacy_pool_created` | `incremental` | ✅ | Up to 4 tokens (token0–token3) |
| Staging | `staging/dex/balancer/stg_balancer_v2_pool_created.sql` | `stg_balancer_v2_pool_created` | `incremental` | ✅ | Up to 8 tokens (token0–token7); pool = first 20 bytes of poolId |
| Staging | `staging/dex/balancer/stg_balancer_v3_pool_created.sql` | `stg_balancer_v3_pool_created` | `incremental` | ✅ | Up to 8 tokens (token0–token7); fee = swapFeePercentage |
| Staging | `staging/dex/stg_dex_pool_token_transfers.sql` | `stg_dex_pool_token_transfers` | `incremental` (delete+insert) | ✅ | One row per transfer; signed amounts (inflow +, outflow −) |
| Intermediate | `intermediate/dex/int_dex_pool_created.sql` | `int_dex_pool_created` | `view` | ✅ | UNION ALL of all pool_created staging; normalises to shared schema with token0–token7, fee, tick_spacing, hooks |
| Intermediate | `intermediate/dex/int_dex_pool_daily_net_change.sql` | `int_dex_pool_daily_net_change` | `view` | ✅ | Daily `SUM(amount)` per (blockchain, pool, token) — no spine, no cumulative logic |
| Mart | `marts/dex/fact_dex_pool_daily_token_balance.sql` | `fact_dex_pool_daily_token_balance` | `table` | ✅ | Daily spine + gap-fill + cumulative balance window function; rows where `balance ≤ 0` excluded |

### Lineage

```
dim_dex_factory_addresses (inline VALUES)
        │
        ▼ filters pool creation events to tracked factories
stg_{protocol}_{version}_pool_created  (one model per protocol/version)
        │
        ▼ UNION ALL, normalised schema
int_dex_pool_created  ←  blockchain, pool, protocol, version, token0..token7, fee, tick_spacing, hooks, ...
        │
        ▼ builds (pool_address, token_address) whitelist per (blockchain, pool, min_block_time)
stg_dex_pool_token_transfers  ←  blockchain, block_date, pool, protocol, version, token_address, symbol, amount (signed), ...
        │
        ▼ daily GROUP BY (view — no spine, no gap-fill)
int_dex_pool_daily_net_change  ←  day, blockchain, pool, protocol, version, token_address, symbol, net_change
        │
        ▼ cross join utils.days from min_block_time per (pool, token) + cumulative window function
fact_dex_pool_daily_token_balance  ←  day, blockchain, pool, protocol, version, token_address, symbol, net_change, balance
```

### `fact_dex_pool_daily_token_balance` Schema

| Column | Type | Description |
|--------|------|-------------|
| `day` | date | Calendar date (UTC) |
| `blockchain` | varchar | Chain name, lowercase |
| `pool` | varbinary | Pool contract address (or PoolManager address for Uniswap V4) |
| `protocol` | varchar | Protocol name, lowercase (e.g. `uniswap`, `curve`, `sushiswap`) |
| `version` | varchar | Protocol version string (e.g. `2`, `3`, `4`, `stableswap_ng`) |
| `token_address` | varbinary | ERC-20 token contract address |
| `symbol` | varchar | Token symbol |
| `net_change` | double | Net token flow into the pool on this day (inflow − outflow); NULL on gap-filled days with no transfers |
| `balance` | double | Cumulative token balance held by the pool at end of day; rows where balance ≤ 0 are excluded |

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Uniswap V4 pool identifier | `contract_address` (PoolManager) | V4 has no individual pool contracts — all liquidity is held in one PoolManager per chain. Balance is tracked at the PoolManager level. |
| Multi-token Curve pools | token0–token7 columns in `int_dex_pool_created` | Covers twocrypto_ng (2), tricrypto_ng (3), stableswap_legacy (≤4), stableswap_ng (≤8). NULL slots for missing tokens produce zero rows in the transfer whitelist. |
| Signed amounts in staging | Inflow +, outflow − in `stg_dex_pool_token_transfers` | Enables simple `SUM(amount)` for daily net change without CASE WHEN downstream. |
| WHERE semi-join in staging | `(blockchain, contract_address) IN (SELECT ...)` alongside INNER JOIN | Trino predicate pushdown uses an explicit WHERE semi-join to prune the large `tokens.transfers` table at scan time; relying on the JOIN condition alone is insufficient. |
| balance > 0 filter in mart | Exclude rows where `balance ≤ 0` | Removes fully-drained pools and rounding/accounting artefacts. |
| Gap-filling in mart | `utils.days` cross-joined from `min_block_time` per (pool, token) | Produces a continuous daily series; `net_change` is NULL on quiet days but `balance` carries forward correctly via the cumulative window. |

---

---

## Token Supply Pipeline

Models that track the circulating supply of labelled ERC-20 tokens across all chains represented in `dim_labels`.

### Supply Logic

- **Mints** = transfers `FROM` the zero address (`0x000...000`) — new tokens entering circulation
- **Burns** = transfers `TO` the zero address (`0x000...000`) — tokens leaving circulation
- **Circulating supply** = cumulative running sum of `net_change` (mint − burn) per chain, computed in `fact_token_daily_supply`

### Token Scope

Driven by `dim_labels` filtered to `type = 'token'`. Amounts sourced directly from `tokens.transfers` (decimal-adjusted). To add tokens, append rows to `dim_labels.sql`.

### Model Inventory

| Layer | Model | Alias | Materialization | Status | Notes |
|-------|-------|-------|----------------|--------|-------|
| Utils | `utils/tokens/dim_labels.sql` | `dim_labels` | `view` | ✅ | Token scope + labels/categories + `min_block_number` / `min_block_time` per chain |
| Staging | `staging/tokens/stg_token_mint_burn_events.sql` | `stg_token_mint_burn_events` | `incremental` (delete+insert) | ✅ | Raw mint/burn rows with `event_type`; one row per transfer |
| Intermediate | `intermediate/tokens/int_token_daily_net_change.sql` | `int_token_daily_net_change` | `view` | ✅ | Daily GROUP BY only — no spine, no gap-fill, no cumulative columns |
| Mart | `marts/tokens/fact_token_daily_supply.sql` | `fact_token_daily_supply` | `table` | ✅ | Owns the daily spine, gap-fill, and cumulative window functions; price join deferred |

### Lineage

```
dim_labels (min_block_number, min_block_time)
        │
        ▼ (inner join + WHERE semi-join, filter block_number >= min_block_number)
tokens.transfers (mints/burns only)
        │
        ▼ raw rows + event_type column
stg_token_mint_burn_events
        │
        ▼ daily GROUP BY (view — no spine, no gap-fill)
int_token_daily_net_change  ← day, blockchain, contract_address, mint_volume, burn_volume, net_change
        │
        ▼ cross join utils.days from min_block_time + left join net_changes + cumulative window functions
fact_token_daily_supply  ← date, blockchain, contract_address, symbol, category, mint_volume, burn_volume, net_change, mint_volume_cumulative, burn_volume_cumulative, circulating_supply
```

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| `min_block_number` filter | Join condition `block_number >= l.min_block_number` | Skips pre-deployment blocks; improves scan performance |
| `event_type` column | `'mint'` / `'burn'` in staging | Makes downstream aggregation readable with `CASE WHEN event_type = 'mint'` |
| Gap-filling | `utils.days` cross-joined with `min_block_time` from `dim_labels` | Generates all days from deployment date; no hardcoded start dates needed |
| Cumulative columns | Window functions in mart (`fact_token_daily_supply`) | `mint_volume_cumulative`, `burn_volume_cumulative`, `circulating_supply` — intermediate is a cheap view |
| Burn address | Zero address only (`0x000...000`) | Matches working query exactly |

### `fact_token_daily_supply` Schema

| Column | Type | Description |
|--------|------|-------------|
| `date` | date | Calendar date (UTC) |
| `blockchain` | varchar | Chain name, lowercase |
| `contract_address` | varbinary | Token contract address |
| `symbol` | varchar | Token symbol (from `dim_labels.name`) |
| `category` | varchar | Asset category from `dim_labels` (e.g. `stablecoin`, `rwa`) |
| `mint_volume` | double | Tokens minted on this day; NULL on gap-filled days with no activity |
| `burn_volume` | double | Tokens burned on this day (positive figure); NULL on gap-filled days with no activity |
| `net_change` | double | `mint_volume − burn_volume` on this day; NULL on gap-filled days |
| `mint_volume_cumulative` | double | Cumulative mints from deployment to this day |
| `burn_volume_cumulative` | double | Cumulative burns from deployment to this day |
| `circulating_supply` | double | Running net supply = `mint_volume_cumulative − burn_volume_cumulative` |

---

## Token Holder Balance Pipeline

Models that track the daily token balance per wallet for tokens in `dim_labels`.

### Architecture

All ERC-20/native transfers for whitelisted tokens are split into two signed rows per event (inflow / outflow), producing a wallet-level ledger. Daily net change is aggregated per wallet, then accumulated into a running balance over a gap-filled days spine anchored to the token's deployment date.

### Model Inventory

| Layer | Model | Alias | Materialization | Status | Notes |
|-------|-------|-------|----------------|--------|-------|
| Utils | `utils/tokens/dim_labels.sql` | `dim_labels` | `view` | ✅ | Token scope + `min_block_time` per chain (spine anchor) |
| Staging | `staging/tokens/stg_token_holder_transfers.sql` | `stg_token_holder_transfers` | `incremental` (delete+insert) | ✅ | Two rows per transfer: inflow (wallet = to, amount +) and outflow (wallet = from, amount −). Zero address excluded as wallet. |
| Intermediate | `intermediate/tokens/int_token_holder_daily_net_change.sql` | `int_token_holder_daily_net_change` | `view` | ✅ | Daily GROUP BY per (wallet, token) — no spine, no cumulative logic |
| Mart | `marts/tokens/fact_token_holder_daily_balance.sql` | `fact_token_holder_daily_balance` | `table` | ✅ | Days spine + gap-fill + cumulative balance window; rows where `balance ≤ 0` excluded |

### Lineage

```
dim_labels (min_block_time — spine anchor)
        │
        ▼ inner join + WHERE semi-join on (blockchain, contract_address)
tokens.transfers (all transfers, not just mint/burn)
        │
        ▼ two rows per transfer: inflow (wallet = "to") and outflow (wallet = "from")
stg_token_holder_transfers  [incremental, delete+insert, 3-day lookback]
        │
        ▼ daily GROUP BY per (blockchain, contract_address, wallet_address)
int_token_holder_daily_net_change  [view]
        │
        ▼ cross join utils.days from min_block_time per (wallet, token) + cumulative window
fact_token_holder_daily_balance  [table]
```

### `fact_token_holder_daily_balance` Schema

| Column | Type | Description |
|--------|------|-------------|
| `day` | date | Calendar date (UTC) |
| `blockchain` | varchar | Chain name, lowercase |
| `contract_address` | varbinary | Token contract address |
| `wallet_address` | varbinary | Wallet holding the token |
| `symbol` | varchar | Token symbol |
| `category` | varchar | Asset category from dim_labels (e.g. `stablecoin`, `rwa`) |
| `min_block_time` | timestamp | Token deployment timestamp (spine anchor) |
| `net_change` | double | Net token flow into the wallet on this day; NULL on gap-filled days |
| `balance` | double | Cumulative balance at end of day; rows where balance ≤ 0 are excluded |

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Include mint/burn transfers | Yes | Mints and burns change wallet balances; excluding them would make balances incorrect |
| Zero address as wallet | Excluded in both UNION branches | Zero address is not a token holder |
| Unique key | `(blockchain, tx_hash, evt_index, event_type)` | One transfer produces two rows; `event_type` differentiates them |
| WHERE semi-join | `(blockchain, contract_address) IN (SELECT ...)` alongside INNER JOIN | Required Trino scan pushdown pattern (CLAUDE.md) |
| Spine anchor | `min_block_time` from `dim_labels` per (blockchain, contract_address) | Uses token deployment date — consistent with the supply pipeline; avoids per-wallet MIN aggregation |
| balance > 0 filter | Exclude rows where `balance ≤ 0` | Removes fully-exited wallets and rounding artefacts |

---

## Open Questions & Design Decisions

Track architectural decisions and open questions here. Once resolved, document the decision and rationale.

| # | Question | Status | Decision |
|---|----------|--------|---------|
| 1 | What are the exact Fluid decoded source tables in Dune? | ❓ Open | — |
| 2 | Should Morpho vault logic live in `marts/morpho/` or `marts/lending/`? | ❓ Open | — |
| 3 | Should `fluid_operates` be split into separate deposit/borrow/etc. models, or kept as one? | ❓ Open | — |
| 4 | What is the preferred materialization for staging models — `view` or `incremental`? | ❓ Open | — |
| 5 | Should price models prefer Chainlink oracle prices, DEX-derived prices, or a blended approach? | ❓ Open | — |
| 6 | Do any marts need multi-chain support (e.g., Arbitrum, Base) from the start, or Ethereum-only first? | ❓ Open | — |

---

## Materialization Strategy

See CLAUDE.md → "Materialization Strategy" for the authoritative rules.

---

## Lineage Overview

```
Sources (Dune delta_prod)
    │
    ▼
staging/           ← Clean raw events per protocol
    │
    ▼
utils/tokens/      ← Token/address enrichment (joins in intermediate or marts)
    │
    ▼
intermediate/      ← Cross-protocol unions, business logic
    │
    ▼
marts/             ← Final analytics tables (exposed to dashboards/APIs)
```
