# Job: Refresh Curve TwoCrypto NG Factory Deployments

## Goal

Check for new Curve TwoCrypto NG factory contract deployments not yet tracked in this project,
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

`twocrypto_ng` — TwoCrypto NG (2023+). 2-token volatile pools.

## Current Factory Addresses (as of 2026-03-13)

Source: curve-js `src/constants/network_constants.ts`

| Chain | Address |
|-------|---------|
| ethereum | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| polygon | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| fantom | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| avalanche_c | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| arbitrum | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| optimism | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| gnosis | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| kava | 0xd3B17f862956464ae4403cCF829CE69199856e1e |
| celo | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| zksync | 0xf3a546AF64aFd6BB8292746BA66DB33aFAE72114 |
| base | 0xc9Fe0C63Af9A39402e8a5514f9c43Af0322b665F |
| bnb | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| fraxtal | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |
| mantle | 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F |

## What to Do

1. Read the current contents of `models/utils/dex/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the curve-js source above
3. Compare — identify any (blockchain, contract_address) pairs in the official list that are
   NOT already in the SQL file for `protocol = 'curve'` and `version = 'twocrypto_ng'`
4. For each missing deployment, add a new row with the correct protocol, version, blockchain,
   contract_address, and `min_block_number` (look up from a block explorer)
5. Do not remove or modify any existing rows
6. Do not add duplicate rows
7. Group new rows under the `-- Curve TwoCrypto NG` comment header

For methodology on finding block numbers, verifying chain names, and computing topic0 — see
`jobs/NEW_MODEL_CHECKLIST.md`.

## Event ABI and topic0

Event: `TwocryptoPoolDeployed`
Note: lowercase 'c' in "Twocrypto" — exact spelling matters for topic0.

Signature: `TwocryptoPoolDeployed(address,string,string,address[2],address,bytes32,uint256[2],uint256,uint256,uint256,uint256,address)`
**topic0:** `0x8152a3037e3dc54154ad0d2cadb1cf7e1d1b9e2b625faa3dfb4fe03d609102ca`

Decoded fields: `pool` (indexed), `coins[1]` as token0, `coins[2]` as token1 (Trino 1-based indexing)

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

These entries power `stg_curve_twocrypto_ng_pool_created`, which decodes `TwocryptoPoolDeployed`
events and feeds into `int_dex_pool_created` via UNION ALL.
Adding new factory address rows causes the staging model to automatically pick up historical
and future pool creation events on the next incremental (or first-time) run.
