# Job: Refresh Curve StableSwap Legacy Factory Deployments

## Goal

Check for new Curve StableSwap Legacy factory contract deployments not yet tracked in this
project, and add them to `dim_dex_factory_addresses.sql`.

## Suggested Frequency

Monthly, or after any Curve announcement of a new chain deployment.

## Source of Truth

Curve's deployment docs (legacy addresses are not in curve-js):
https://curve.readthedocs.io/ref-addresses.html

Cross-reference with:
- Curve GitHub org: https://github.com/curvefi

## Target File

```
models/utils/factory_addresses/dim_dex_factory_addresses.sql
```

Columns: `protocol`, `version`, `blockchain`, `contract_address`, `min_block_number`

## Factory Type

`stableswap_legacy` — Pre-NG StableSwap. 2–4 token stable pools using the original Curve AMM
design. Pool address is NOT emitted in the deployment event — recovered from `evms.creation_traces`.

## Current Factory Addresses (as of 2026-03-13)

Source: https://curve.readthedocs.io/ref-addresses.html

| Chain | Address |
|-------|---------|
| ethereum | 0xB9fC157394Af804a3578134A6585C0dc9cc990d4 |
| ethereum | 0x0959158b6040d32d04c301a72cbfd6b39e21c9ae |
| arbitrum | 0xb17b674D9c5CB2e441F8e196a2f048A81355d031 |
| avalanche_c | 0xb17b674D9c5CB2e441F8e196a2f048A81355d031 |
| optimism | 0x2db0E83599a91b508Ac268a6197b8B14F5e72840 |
| fantom | 0x686d67265703d1f124c45e33d47d794c566889ba |
| polygon | 0x722272d36ef0da72ff51c5a65db7b870e2e8d4ee |
| gnosis | 0xD19Baeadc667Cf2015e395f2B08668Ef120f41F5 |

> Note: `0x0959158b…` may be a MetaPool factory with a different event signature — the topic0
> filter returns 0 rows for it safely, so it is included but produces no output.

## What to Do

1. Read the current contents of `models/utils/factory_addresses/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the source above
3. Compare — identify any (blockchain, contract_address) pairs in the official list that are
   NOT already in the SQL file for `protocol = 'curve'` and `version = 'stableswap_legacy'`
4. For each missing deployment, add a new row with the correct protocol, version, blockchain,
   contract_address, and `min_block_number` (look up from a block explorer)
5. Do not remove or modify any existing rows
6. Do not add duplicate rows
7. Group new rows under the `-- Curve StableSwap Legacy` comment header

For methodology on finding block numbers, verifying chain names, and computing topic0 — see
`jobs/NEW_MODEL_CHECKLIST.md`.

## Event ABI and topic0

Event: `PlainPoolDeployed`

Signature: `PlainPoolDeployed(address[4],uint256,uint256,address)`
**topic0:** `0x5b4a28c940282b5bf183df6a046b8119cf6edeb62859f75e835eb7ba834cce8d`

Pool address is NOT in the event. Recovered from `evms.creation_traces`: the factory creates
the pool contract in the same tx, so `c.address` where `c."from" = factory` = the pool.
`coins` is a fixed `address[4]` — slots with no token are `0x000...000` (filtered to null
in staging).

## Filling in `min_block_number` Values

Legacy stableswap rows have block numbers filled in. For any new rows:
1. Find the factory contract on the chain's block explorer
2. Note the block number of the contract's creation transaction
3. Add as the `min_block_number` value in the new row

## Validation Rules

- Never delete existing rows
- Never modify existing `min_block_number` values (unless correcting a confirmed error)
- No duplicate (blockchain, contract_address) pairs for the same (protocol, version)
- `contract_address` must be checksummed hex

## Output / Report

After completing the task, report:
- How many new rows were added
- Which chains/addresses were added
- Any chains not confirmed in Dune's `evms.logs` (omit those rows, note in report)
- Confirm no existing rows were modified

## Context

These entries power `stg_curve_stableswap_legacy_pool_created`, which decodes `PlainPoolDeployed`
events and recovers pool addresses from `evms.creation_traces`. Feeds into `int_dex_pool_created`
via UNION ALL. Adding new factory address rows causes the staging model to automatically pick
up historical and future pool creation events on the next incremental (or first-time) run.
