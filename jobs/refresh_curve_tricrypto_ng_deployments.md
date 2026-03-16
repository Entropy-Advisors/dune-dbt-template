# Job: Refresh Curve Tricrypto NG Factory Deployments

## Goal

Check for new Curve Tricrypto NG factory contract deployments not yet tracked in this project,
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
models/utils/factory_addresses/dim_dex_factory_addresses.sql
```

Columns: `protocol`, `version`, `blockchain`, `contract_address`, `min_block_number`

## Factory Type

`tricrypto_ng` — Tricrypto NG (2023+). 3-token volatile pools.

## Current Factory Addresses (as of 2026-03-13)

Source: curve-js `src/constants/network_constants.ts`

| Chain | Address |
|-------|---------|
| ethereum | 0x0c0e5f2fF0ff18a3be9b835635039256dC4B4963 |
| polygon | 0xC1b393EfEF38140662b91441C6710Aa704973228 |
| fantom | 0x9AF14D26075f142eb3F292D5065EB3faa646167b |
| avalanche_c | 0x3d6cB2F6DcF47CDd9C13E4e3beAe9af041d8796a |
| arbitrum | 0xbC0797015fcFc47d9C1856639CaE50D0e69FbEE8 |
| optimism | 0xc6C09471Ee39C7E30a067952FcC89c8922f9Ab53 |
| gnosis | 0xb47988aD49DCE8D909c6f9Cf7B26caF04e1445c8 |
| kava | 0x3d6cB2F6DcF47CDd9C13E4e3beAe9af041d8796a |
| celo | 0x3d6cB2F6DcF47CDd9C13E4e3beAe9af041d8796a |
| zksync | 0x5d4174C40f1246dABe49693845442927d5929f0D |
| base | 0xA5961898870943c68037F6848d2D866Ed2016bcB |
| bnb | 0xc55837710bc500F1E3c7bb9dd1d51F7c5647E657 |
| fraxtal | 0xc9Fe0C63Af9A39402e8a5514f9c43Af0322b665F |
| mantle | 0x0C9D8c7e486e822C29488Ff51BFf0167B4650953 |

## What to Do

1. Read the current contents of `models/utils/factory_addresses/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the curve-js source above
3. Compare — identify any (blockchain, contract_address) pairs in the official list that are
   NOT already in the SQL file for `protocol = 'curve'` and `version = 'tricrypto_ng'`
4. For each missing deployment, add a new row with the correct protocol, version, blockchain,
   contract_address, and `min_block_number` (look up from a block explorer)
5. Do not remove or modify any existing rows
6. Do not add duplicate rows
7. Group new rows under the `-- Curve Tricrypto NG` comment header

For methodology on finding block numbers, verifying chain names, and computing topic0 — see
`jobs/NEW_MODEL_CHECKLIST.md`.

## Event ABI and topic0

Event: `TricryptoPoolDeployed`

Signature: `TricryptoPoolDeployed(address,string,string,address,address[3],address,bytes32,uint256,uint256,uint256,uint256,uint256,address)`
**topic0:** `0xa307f5d0802489baddec443058a63ce115756de9020e2b07d3e2cd2f21269e2a`

Decoded fields: `pool` (non-indexed, in data), `coins[1]` as token0, `coins[2]` as token1,
`coins[3]` as token2 (Trino 1-based indexing)

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

These entries power `stg_curve_tricrypto_ng_pool_created`, which decodes `TricryptoPoolDeployed`
events and feeds into `int_dex_pool_created` via UNION ALL.
Adding new factory address rows causes the staging model to automatically pick up historical
and future pool creation events on the next incremental (or first-time) run.
