# Job: Refresh All Factory Addresses

## Goal

Run all protocol-specific factory address refresh jobs in sequence. Check every tracked DEX protocol for new chain deployments not yet in `dim_dex_factory_addresses.sql` and add any missing rows.

This is the master job run by `.github/workflows/refresh_factory_addresses.yml` on a monthly schedule. It can also be run manually.

## What to Do

Run each of the following jobs in order. For each one, follow its instructions fully before moving to the next:

1. `jobs/refresh_uniswap_v2_deployments.md`
2. `jobs/refresh_uniswap_v3_deployments.md`
3. `jobs/refresh_uniswap_v4_deployments.md`
4. `jobs/refresh_sushiswap_v2_deployments.md`
5. `jobs/refresh_sushiswap_v3_deployments.md`
6. `jobs/refresh_pancakeswap_v2_deployments.md`
7. `jobs/refresh_pancakeswap_v3_deployments.md`
8. `jobs/refresh_gammaswap_deployments.md`
9. `jobs/refresh_camelot_v2_deployments.md`
10. `jobs/refresh_camelot_v3_deployments.md`
11. `jobs/refresh_curve_twocrypto_ng_deployments.md`
12. `jobs/refresh_curve_tricrypto_ng_deployments.md`
13. `jobs/refresh_curve_stableswap_ng_deployments.md`
14. `jobs/refresh_curve_stableswap_legacy_deployments.md`

All edits go to the same file: `models/utils/dex/dim_dex_factory_addresses.sql`.

## Rules

- Never delete or modify existing rows
- No duplicate (protocol, version, blockchain, contract_address) pairs
- `min_block_number` should be a confirmed positive integer when available; use `null` if the block number cannot be found without a block explorer lookup — note the deployment tx hash in a comment. Never use 0.
- Only add addresses from each protocol's official source (see individual job files)

## Output / Report

After completing all jobs, report:

- **Per protocol:** how many new rows were added (or "no changes")
- **Total:** rows added across all protocols
- **Skipped:** any deployments that could not be confirmed (block number unknown, chain not in Dune, etc.)
- **No existing rows modified** — confirm explicitly
