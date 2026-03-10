# Job: Refresh PancakeSwap V3 Factory Deployments

## Goal

Check for new PancakeSwap V3 factory contract deployments that are not yet tracked in this project, and add them to `dim_dex_factory_addresses.sql`.

## Suggested Frequency

Monthly, or after any PancakeSwap announcement of a new chain deployment.

## Source of Truth

PancakeSwap's official V3 deployment registry:
https://developer.pancakeswap.finance/contracts/v3/addresses

Cross-reference with:
- PancakeSwap's GitHub org (https://github.com/pancakeswap) for any new chain-specific deployment repos

## Target File

```
models/utils/factory_addresses/dim_dex_factory_addresses.sql
```

Columns: `blockchain`, `contract_address`, `min_block_number`

## What to Do

1. Read the current contents of `models/utils/factory_addresses/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the source URL above
3. Compare — identify any (blockchain, contract_address) pairs in the official list that are NOT in the CSV
4. For each missing deployment, add a new row with blockchain, checksummed contract_address, and min_block_number
5. Do not remove or modify any existing rows
6. Do not add duplicate rows

For methodology on finding block numbers, verifying chain names, and computing topic0 — see `jobs/NEW_MODEL_CHECKLIST.md`.

## ABI

- **Event:** `PoolCreated(address,address,uint24,int24,address)`
- **topic0:** `0x783cca1c0412dd0d695e784568c96da2e9c22ff989357a2e8b1d9b2b4e6b7118`

**Important:** Uniswap V3 and SushiSwap V3 share the same topic0 (PancakeSwap V3 forked Uniswap V3). Do not confuse PancakeSwap V3 factory addresses with those protocols. Only add addresses from the official PancakeSwap V3 docs.

## Validation Rules

- Never delete existing rows
- Never modify existing `min_block_number` values
- No duplicate (blockchain, contract_address) pairs
- `contract_address` must be checksummed hex
- `min_block_number` must be a confirmed positive integer — never 0
- The same factory address may appear on multiple chains (CREATE2) — valid as long as blockchain differs

## Output / Report

After completing the task, report:
- How many new rows were added
- Which chains/addresses were added
- Any block numbers that could not be confirmed (omit those rows, note in report)
- Any chains not confirmed in Dune's `evms.logs`
- Confirm no existing rows were modified

## Context

These entries in `dim_dex_factory_addresses.sql` power `stg_pancakeswap_v3_pool_created`, which decodes `PoolCreated` events from `evms.logs` for all tracked PancakeSwap V3 factory addresses. V3 pools have fee tiers and tick spacing decoded directly from the event. Adding a new row directly to `dim_dex_factory_addresses.sql` means the staging model will automatically pick up historical and future pool creation events for that deployment on the next incremental run.
