# Job: Refresh Camelot V2 Factory Deployments

## Goal

Check for new Camelot V2 (AMMv2) factory contract deployments that are not yet tracked in this project, and add them to `dim_dex_factory_addresses.sql`.

## Suggested Frequency

Monthly, or after any Camelot announcement of a new chain deployment.

## Source of Truth

Camelot's official deployment registry:
https://docs.camelot.exchange/contracts/arbitrum/one-mainnet

For Orbit chain deployments:
https://docs.camelot.exchange/orbital-liquidity-network

## Target File

```
models/utils/dex/dim_dex_factory_addresses.sql
```

Columns: `blockchain`, `contract_address`, `min_block_number`

## What to Do

1. Read the current contents of `models/utils/dex/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the source URLs above
3. Compare — identify any (blockchain, contract_address) pairs in the official list that are NOT in the CSV
4. For each missing deployment, add a new row with blockchain, checksummed contract_address, and min_block_number
5. Do not remove or modify any existing rows
6. Do not add duplicate rows

For methodology on finding block numbers, verifying chain names, and computing topic0 — see `jobs/NEW_MODEL_CHECKLIST.md`.

## ABI

- **Event:** `PairCreated(address,address,address,uint256)`
- **topic0:** `0x0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9`

**Important:** Uniswap V2, SushiSwap V2, PancakeSwap V2, and GammaSwap share the same topic0 (all are Uniswap V2 forks). Do not confuse Camelot V2 factory addresses with those protocols. Only add addresses from the official Camelot docs.

## Known Gaps

The following deployments exist but are not yet in `dim_dex_factory_addresses.sql` — add them when block numbers are confirmed:

**Arbitrum One (AMMv2):** `0x6EcCab422D763aC031210895C81787E87B43A652` — block number not yet confirmed (check Arbiscan contract creator tx)

**Orbit chains** (all use factory `0x7d8c6B58BA2d40FC6E34C25f9A488067Fe0D2dB4`):
apechain, aleph_zero, reya, winr, corn, duckchain, edu, sanko — block numbers unknown, Dune chain names unverified (may not be indexed yet)

**Note on V4:** Camelot V4 (AMMv4, Algebra Integral) uses a different factory (`0xBefC4b405041c5833f53412fF997ed2f697a2f37`) and is out of scope for this model — it may have a different event interface.

## Validation Rules

- Never delete existing rows
- Never modify existing `min_block_number` values
- No duplicate (blockchain, contract_address) pairs
- `contract_address` must be checksummed hex
- `min_block_number` must be a confirmed positive integer — never 0, never a placeholder string

## Output / Report

After completing the task, report:
- How many new rows were added
- Which chains/addresses were added
- Any block numbers that could not be confirmed (omit those rows, note in report)
- Any chains not confirmed in Dune's `evms.logs`
- Confirm no existing rows were modified

## Context

These entries in `dim_dex_factory_addresses.sql` power `stg_camelot_v2_pool_created`, which decodes `PairCreated` events from `evms.logs` for all tracked Camelot V2 factory addresses. Adding a new row directly to `dim_dex_factory_addresses.sql` means the staging model will automatically pick up historical and future pool creation events for that deployment on the next incremental run.
