# Job: Refresh Curve Finance Factory Deployments

## Goal

Check for new Curve Finance factory contract deployments that are not yet tracked in this project,
and add them to `dim_dex_factory_addresses.sql`. Curve has 4 distinct factory types — each must
be checked separately.

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

## Factory Types

| version string       | Factory type             | Notes |
|----------------------|--------------------------|-------|
| `stableswap_ng`      | StableSwap NG (2023+)    | Fully implemented. 2–8 token stable pools. Pool address recovered from evms.creation_traces. |
| `twocrypto_ng`       | TwoCrypto NG (2023+)     | Fully implemented. 2-token volatile pools. |
| `tricrypto_ng`       | Tricrypto NG (2023+)     | Fully implemented. 3-token volatile pools. |
| `stableswap_legacy`  | Pre-NG StableSwap        | Fully implemented. Pool address recovered from evms.creation_traces. |

## Current Factory Addresses (as of 2026-03-13)

Source: curve-js `src/constants/network_constants.ts`

### StableSwap NG (`stableswap_ng`)
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

### TwoCrypto NG (`twocrypto_ng`)
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

### Tricrypto NG (`tricrypto_ng`)
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

### Legacy StableSwap (`stableswap_legacy`)
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

## What to Do

1. Read the current contents of `models/utils/factory_addresses/dim_dex_factory_addresses.sql`
2. Fetch the official deployment list from the curve-js source above
3. For each factory type, compare — identify any (blockchain, contract_address) pairs in the
   official list that are NOT already in the SQL file
4. For each missing deployment, add a new row with the correct protocol, version, blockchain,
   contract_address, and `min_block_number` (look up from a block explorer)
5. Do not remove or modify any existing rows
6. Do not add duplicate rows
7. Group new rows under the appropriate `-- Curve <type>` comment header

For methodology on finding block numbers, verifying chain names, and computing topic0 — see
`jobs/NEW_MODEL_CHECKLIST.md`.

## Event ABIs and topic0

### TwoCrypto NG — `TwocryptoPoolDeployed`
Note: lowercase 'c' in "Twocrypto" — exact spelling matters for topic0.

Signature: `TwocryptoPoolDeployed(address,string,string,address[2],address,bytes32,uint256[2],uint256,uint256,uint256,uint256,address)`
**topic0:** `0x8152a3037e3dc54154ad0d2cadb1cf7e1d1b9e2b625faa3dfb4fe03d609102ca`

Decoded fields: `pool` (indexed), `coins[1]` as token0, `coins[2]` as token1 (Trino 1-based indexing)

### Tricrypto NG — `TricryptoPoolDeployed`

Signature: `TricryptoPoolDeployed(address,string,string,address,address[3],address,bytes32,uint256,uint256,uint256,uint256,uint256,address)`
**topic0:** `0xa307f5d0802489baddec443058a63ce115756de9020e2b07d3e2cd2f21269e2a`

Decoded fields: `pool` (non-indexed, in data), `coins[1]` as token0, `coins[2]` as token1

### StableSwap NG — `PlainPoolDeployed`

Signature: `PlainPoolDeployed(address[],uint256,uint256,address)`
**topic0:** `0xd1d60d4611e4091bb2e5f699eeb79136c21ac2305ad609f3de569afc3471eecc`

Pool address is NOT in the event. Recovered from `evms.creation_traces` (c.address where
c."from" = factory, same tx_hash + block_number). coins[1] = token0, coins[2] = token1.

### Legacy StableSwap — `PlainPoolDeployed`

Signature: `PlainPoolDeployed(address[4],uint256,uint256,address)`
**topic0:** `0x5b4a28c940282b5bf183df6a046b8119cf6edeb62859f75e835eb7ba834cce8d`

Pool address is NOT in the event. Recovered from `evms.creation_traces` same as NG above.
coins[1] = token0, coins[2] = token1. Note: 0x0959158b… may be a MetaPool factory with a
different event — the topic0 filter returns 0 rows for it safely.

## Filling in `min_block_number` Values

Legacy stableswap rows now have block numbers filled in. All other Curve factory rows still
have `min_block_number = null`. To fill them in:
1. Find the factory contract on the chain's block explorer
2. Note the block number of the contract's creation transaction
3. Update the corresponding row in `dim_dex_factory_addresses.sql`

Using `null` is safe for correctness (no rows are skipped), but less efficient than a specific
block number (the staging model join will scan from genesis instead of the deployment block).

## Validation Rules

- Never delete existing rows
- Never modify existing `min_block_number` values (unless correcting a confirmed error)
- No duplicate (blockchain, contract_address) pairs for the same (protocol, version)
- `contract_address` must be checksummed hex
- Group rows by factory type under the appropriate comment header
- The same factory address may appear on multiple chains (CREATE2) — valid as long as blockchain differs

## Output / Report

After completing the task, report:
- How many new rows were added per factory type
- Which chains/addresses were added
- Any chains not confirmed in Dune's `evms.logs` (omit those rows, note in report)
- Confirm no existing rows were modified

## Context

These entries power the Curve staging models:
- `stg_curve_twocrypto_ng_pool_created` — decodes `TwocryptoPoolDeployed` events
- `stg_curve_tricrypto_ng_pool_created` — decodes `TricryptoPoolDeployed` events
- `stg_curve_stableswap_ng_pool_created` — STUB (pool address not in event)
- `stg_curve_stableswap_legacy_pool_created` — STUB (ABI unverified)

All 4 models feed into `int_dex_pool_created` via UNION ALL branches.
Adding new factory address rows causes the staging models to automatically pick up historical
and future pool creation events on the next incremental (or first-time) run.
