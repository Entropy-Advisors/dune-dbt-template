# Job: Refresh Uniswap V4 PoolManager Deployments

## Goal

Check for new Uniswap V4 PoolManager deployments that are not yet tracked in this project, and add them to `dim_dex_factory_addresses.sql`.

## Suggested Frequency

Monthly, or after any Uniswap announcement of a new chain deployment.

## Source of Truth

Uniswap's official V4 deployment registry:
https://docs.uniswap.org/contracts/v4/deployments

Cross-reference with:
- Uniswap's GitHub org (https://github.com/Uniswap/v4-periphery) for deployment scripts
- Uniswap governance forum announcements for new chain deployments

## Target File

```
models/utils/factory_addresses/dim_dex_factory_addresses.sql
```

Columns: `protocol='uniswap'`, `version='4'`, `blockchain`, `contract_address`, `min_block_number`

## What to Do

1. Read the current Uniswap V4 entries in `models/utils/factory_addresses/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the source URL above
3. Compare — identify any (blockchain, contract_address) pairs in the official list that are NOT already tracked
4. For each missing deployment, add a new row with blockchain, checksummed contract_address, and min_block_number
5. Do not remove or modify any existing rows
6. Do not add duplicate rows

**Important — block numbers:** The official docs do not list deployment block numbers. Find them via the chain's block explorer (search the PoolManager address → Contract Creator transaction → block number). Do NOT use 0 or 999999999 — only confirmed positive integers.

For methodology on finding block numbers, verifying chain names, and computing topic0 — see `jobs/NEW_MODEL_CHECKLIST.md`.

## ABI

- **Event:** `Initialize(bytes32,address,address,uint24,int24,address,uint160,int24)`
- **topic0:** `0xdd466e674ea557f56295e2d0218a125ea4b4f0f6f3307b95f85e6110838d6438`

**V4 architecture difference:** Unlike V2/V3, there is no factory contract. Each chain has a single **PoolManager** contract that handles all pool initialization. The `contract_address` in every V4 row is the PoolManager — all `Initialize` events come from this one contract per chain.

**Do not confuse with community tables:** The Dune community table `uniswap_v4_multichain.poolmanager_evt_initialize` may include unofficial or miscategorised deployments. Only add addresses from the official Uniswap V4 docs.

## Validation Rules

- Never delete existing rows
- Never modify existing `min_block_number` values
- No duplicate (blockchain, contract_address) pairs
- `contract_address` must be checksummed hex
- `min_block_number` must be a confirmed positive integer — never 0 or 999999999
- One PoolManager address per chain — if the same address appears on multiple chains, it is valid as long as `blockchain` differs

## Output / Report

After completing the task, report:
- How many new rows were added
- Which chains/addresses were added
- Any block numbers that could not be confirmed (omit those rows, note in report)
- Any chains not confirmed in Dune's `evms.logs`
- Confirm no existing rows were modified

## Context

These entries in `dim_dex_factory_addresses.sql` power `stg_uniswap_v4_pool_initialized`, which decodes `Initialize` events from `evms.logs` for all tracked Uniswap V4 PoolManager addresses. V4 pools are identified by a `PoolId` (bytes32 hash of the pool key), not a separate contract address. Adding a new row directly to `dim_dex_factory_addresses.sql` means the staging model will automatically pick up historical and future pool initialization events for that deployment on the next incremental run.
