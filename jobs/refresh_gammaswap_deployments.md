# Job: Refresh GammaSwap Factory Deployments

## Goal

Check for new GammaSwap factory contract deployments that are not yet tracked in this project, and add them to `dim_dex_factory_addresses.sql`.

## Suggested Frequency

Monthly, or after any GammaSwap announcement of a new chain deployment.

## Source of Truth

GammaSwap's official deployment registry:
https://docs.gammaswap.com/resources/contract-addresses

Cross-reference with:
- GammaSwap's GitHub org (https://github.com/gammaswap) for any new chain-specific deployment repos

## Target File

```
models/utils/dex/dim_dex_factory_addresses.sql
```

Columns: `blockchain`, `contract_address`, `min_block_number`

## What to Do

1. Read the current contents of `models/utils/dex/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the source URL above
3. Compare — identify any (blockchain, contract_address) pairs in the official list that are NOT in the CSV
4. For each missing deployment, add a new row with blockchain, checksummed contract_address, and min_block_number
5. Do not remove or modify any existing rows
6. Do not add duplicate rows

For methodology on finding block numbers, verifying chain names, and computing topic0 — see `jobs/NEW_MODEL_CHECKLIST.md`.

## ABI

- **Event:** `PairCreated(address,address,address,uint256)`
- **topic0:** `0x0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9`

**Important:** Uniswap V2, SushiSwap V2, PancakeSwap V2, and Camelot V2 share the same topic0 (all are Uniswap V2 forks). Do not confuse GammaSwap factory addresses with those protocols. Only add addresses from the official GammaSwap docs.

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

These entries in `dim_dex_factory_addresses.sql` power `stg_gammaswap_pool_created`, which decodes `PairCreated` events from `evms.logs` for all tracked GammaSwap factory addresses. DeltaSwap is the DEX/AMM layer inside GammaSwap — the `version` column is set to `'deltaswap'` to reflect this. Adding a new row directly to `dim_dex_factory_addresses.sql` means the staging model will automatically pick up historical and future pool creation events for that deployment on the next incremental run.
