# New Token Chain Checklist

How to add a new token or blockchain to the token mint/burn supply pipeline.

## When to Use This

Use this checklist when a token you want to track deploys on a new chain, or when adding
a brand-new token to any chain already in `dim_labels`.

---

## Pre-Run Checklist

1. **Find the exact chain name** as used in Dune's `tokens.transfers` table.
   Check via: `SELECT DISTINCT blockchain FROM tokens.transfers LIMIT 100`
   or refer to the mapping in `jobs/NEW_MODEL_CHECKLIST.md`.

2. **Add a row to `dim_labels`** in `models/utils/tokens/dim_labels.sql` for each
   (blockchain, token address) pair. Each row needs:
   - `blockchain` — chain name in lowercase
   - `address` — token contract address as VARBINARY hex literal
   - `name` — human-readable symbol (e.g. `'USDai'`)
   - `label` — protocol identifier in lowercase
   - `type = 'token'`
   - `category` — e.g. `'stablecoin'`, `'ybs'`, `'rwa'`
   - `min_block_number` — deployment block (used to skip pre-deployment blocks in staging)
   - `min_block_time` — deployment timestamp (used as spine start in `fact_token_daily_supply`)

   No SQL changes to any model file — `dim_labels` is the sole token whitelist.

---

## Dev environment: refresh dependent views

`dim_labels` and `int_token_daily_net_change` are `view` materializations — real database objects
that must exist in the dev schema before the mart can run. dbt's `--select fact_token_daily_supply`
does **not** automatically run upstream views; they must be present already.

Run this before the mart step if you are starting fresh in dev, or if either view has been modified
since it was last run:

```bash
set -a && source .env && set +a && uv run dbt run \
  --select dim_labels int_token_daily_net_change
```

This is a no-op if the views are already current — views are cheap and take under 5 seconds.

---

## Run Sequence

```bash
# Step 1: Full-refresh stg_token_mint_burn_events to backfill full history for the new token/chain.
# Required because is_incremental() would skip all history beyond the 3-day lookback.
set -a && source .env && set +a && uv run dbt run \
  --select stg_token_mint_burn_events \
  --full-refresh

# → Read target/run_results.json, append to docs/run_log.csv before continuing.

# Step 2: Rebuild the mart (table materialization — always a full rebuild).
# Ensure dim_labels and int_token_daily_net_change views exist in the schema first (see above).
set -a && source .env && set +a && uv run dbt run \
  --select fact_token_daily_supply

# → Read target/run_results.json, append to docs/run_log.csv.
```

---

## Verification

After the runs complete, query on Dune (dev target):

```sql
SELECT blockchain, count(*) as rows, min(date) as first_day, max(date) as last_day
FROM dune.<team>__tmp_.fact_token_daily_supply
GROUP BY 1
ORDER BY 1
```

Confirm:
- The new chain/token appears in results
- `first_day` is on or before the token deployment date
- `circulating_supply` is non-zero for whitelisted tokens

---

## Notes

- `--full-refresh` on `stg_token_mint_burn_events` scans all of `tokens.transfers` for all
  chains present in `dim_labels`. Cost scales with the number of whitelisted (blockchain, address)
  pairs and how much history they have. This is expected and necessary.
- `int_token_daily_net_change` is a `view` — it must exist in the schema before the mart runs. Refresh it explicitly whenever you modify it, or when setting up a fresh dev environment.
- `fact_token_daily_supply` is a `table` materialization — always a full rebuild (no `--full-refresh`
  flag needed or useful for it).
- Adding a new token to an existing chain requires `--full-refresh` to backfill historical
  mint/burn events. Without it, the incremental staging model will only pick up recent events.
