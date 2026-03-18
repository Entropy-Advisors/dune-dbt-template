# Job: Refresh Camelot V3 Factory Deployments

## Goal

Check for new Camelot V3 (AMMv3, Algebra Finance) factory contract deployments that are not yet tracked in this project, and add them to `dim_dex_factory_addresses.sql`.

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

**IMPORTANT: Camelot V3 uses Algebra Finance V1.9 — this is NOT a Uniswap V3 fork.**

The pool creation event is `Pool`, not `PoolCreated`:

- **Event:** `Pool(address,address,address)`
- **topic0:** `0x91ccaa7a278130b65168c3a0c8d3bcae84cf5e43704342bd3ec0b59e59c036db`
- **Full signature:** `Pool(address indexed token0, address indexed token1, address pool)`
- **No fee or tick_spacing** — Algebra uses dynamic per-pool fees, not fixed fee tiers

To verify this topic0: `cast keccak "Pool(address,address,address)"` or see `jobs/NEW_MODEL_CHECKLIST.md`.

**Important:** The Uniswap V3 topic0 (`0x783cca...`) is different — do not confuse Camelot V3 (Algebra) with Uniswap V3, SushiSwap V3, or PancakeSwap V3. Only add addresses from the official Camelot V3 docs.

**Note on V4:** Camelot V4 (AMMv4, Algebra Integral) uses a different factory (`0xBefC4b405041c5833f53412fF997ed2f697a2f37` on Arbitrum) and is out of scope for this model — create a separate `stg_camelot_v4_pool_created` model if needed.

## Known Gaps

**Orbit chains** — the following are documented Camelot V3 deployments not yet in `dim_dex_factory_addresses.sql` (block numbers unknown, Dune chain names unverified):

- apechain, aleph_zero, reya, winr: factory `0x10aA510d94E094Bd643677bd2964c3EE085Daffc`
- corn, duckchain, edu: factory `0xCf4062Ee235BbeB4C7c0336ada689ed1c17547b6`
- sanko: factory `0xcF8d0723e69c6215523253a190eB9Bc3f68E0FFa`

Add these once block numbers are confirmed and Dune chain names are verified.

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

These entries in `dim_dex_factory_addresses.sql` power `stg_camelot_v3_pool_created`, which decodes `Pool` events from `evms.logs` for all tracked Camelot V3 (Algebra Finance) factory addresses. Unlike Uniswap V3, Algebra pools do not have fixed fee tiers — there is no `fee` or `tick_spacing` in the decoded output. Adding a new row directly to `dim_dex_factory_addresses.sql` means the staging model will automatically pick up historical and future pool creation events for that deployment on the next incremental run.
