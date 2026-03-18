# Job: Refresh Curve StableSwap NG Factory Deployments

## Goal

Check for new Curve StableSwap NG factory contract deployments not yet tracked in this project,
and add them to `dim_dex_factory_addresses.sql`.

## Suggested Frequency

Monthly, or after any Curve announcement of a new chain deployment.

## Source of Truth

Official curve-js library (used by the Curve frontend):
https://github.com/curvefi/curve-js/blob/master/src/constants/network_constants.ts

Cross-reference with:
- Curve's deployment docs: https://curve.readthedocs.io/ref-addresses.html
- Curve GitHub org: https://github.com/curvefi

## Target File

```
models/utils/dex/dim_dex_factory_addresses.sql
```

Columns: `protocol`, `version`, `blockchain`, `contract_address`, `min_block_number`

## Factory Type

`stableswap_ng` — StableSwap NG (2023+). 2–8 token stable pools. Pool address is NOT emitted
in the deployment event — recovered from `evms.creation_traces`.

## Current Factory Addresses (as of 2026-03-13)

Source: curve-js `src/constants/network_constants.ts`

| Chain | Address |
|-------|---------|
| ethereum | 0x6A8cbed756804B16E05E741eDaBd5cB544AE21bf |
| polygon | 0x1764ee18e8B3ccA4787249Ceb249356192594585 |
| fantom | 0xe61Fb97Ef6eBFBa12B36Ffd7be785c1F5A2DE66b |
| avalanche_c | 0x1764ee18e8B3ccA4787249Ceb249356192594585 |
| arbitrum | 0x9AF14D26075f142eb3F292D5065EB3faa646167b |
| optimism | 0x5eeE3091f747E60a045a2E715a4c71e600e31F6E |
| gnosis | 0xbC0797015fcFc47d9C1856639CaE50D0e69FbEE8 |
| kava | 0x1764ee18e8B3ccA4787249Ceb249356192594585 |
| celo | 0x1764ee18e8B3ccA4787249Ceb249356192594585 |
| zksync | 0xFcAb5d04e8e031334D5e8D2C166B08daB0BE6CaE |
| base | 0xd2002373543Ce3527023C75e7518C274A51ce712 |
| fraxtal | 0xd2002373543Ce3527023C75e7518C274A51ce712 |
| mantle | 0x5eeE3091f747E60a045a2E715a4c71e600e31F6E |

> Note: `xlayer` was excluded — verify Dune support before adding.

## What to Do

1. Read the current contents of `models/utils/dex/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the curve-js source above
3. Compare — identify any (blockchain, contract_address) pairs in the official list that are
   NOT already in the SQL file for `protocol = 'curve'` and `version = 'stableswap_ng'`
4. For each missing deployment, add a new row with the correct protocol, version, blockchain,
   contract_address, and `min_block_number` (look up from a block explorer)
5. Do not remove or modify any existing rows
6. Do not add duplicate rows
7. Group new rows under the `-- Curve StableSwap NG` comment header

For methodology on finding block numbers, verifying chain names, and computing topic0 — see
`jobs/NEW_MODEL_CHECKLIST.md`.

## Event ABI and topic0

Event: `PlainPoolDeployed`

Signature: `PlainPoolDeployed(address[],uint256,uint256,address)`
**topic0:** `0xd1d60d4611e4091bb2e5f699eeb79136c21ac2305ad609f3de569afc3471eecc`

Pool address is NOT in the event. Recovered from `evms.creation_traces`: the factory creates
the pool contract in the same tx, so `c.address` where `c."from" = factory` = the pool.
`coins` is a dynamic array — cardinality varies from 2 to 8 per pool.

## Filling in `min_block_number` Values

1. Find the factory contract on the chain's block explorer
2. Note the block number of the contract's creation transaction
3. Add as the `min_block_number` value in the new row

Using `null` is safe for correctness (no rows are skipped), but less efficient than a specific
block number (the staging model join will scan from genesis instead of the deployment block).

## Validation Rules

- Never delete existing rows
- Never modify existing `min_block_number` values (unless correcting a confirmed error)
- No duplicate (blockchain, contract_address) pairs for the same (protocol, version)
- `contract_address` must be checksummed hex
- The same factory address may appear on multiple chains (CREATE2) — valid as long as blockchain differs

## Output / Report

After completing the task, report:
- How many new rows were added
- Which chains/addresses were added
- Any chains not confirmed in Dune's `evms.logs` (omit those rows, note in report)
- Confirm no existing rows were modified

## Context

These entries power `stg_curve_stableswap_ng_pool_created`, which decodes `PlainPoolDeployed`
events and recovers pool addresses from `evms.creation_traces`. Feeds into `int_dex_pool_created`
via UNION ALL. Adding new factory address rows causes the staging model to automatically pick
up historical and future pool creation events on the next incremental (or first-time) run.
