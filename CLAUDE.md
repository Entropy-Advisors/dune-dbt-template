# Claude Agent Instructions

Rules and conventions for AI agents working in this repository.

## Required Setup Before Running Any dbt Commands

### 1. Install uv (if not already installed)

`uv` is the required Python package manager for this project. All dbt commands run through `uv run dbt ...` — never bare `dbt`.

Check if installed:
```bash
which uv
```

If not found, install it:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
```

### 2. Install project dependencies

```bash
uv sync
uv run dbt deps
```

### 3. Set credentials via .env — never inline in commands

Credentials must be loaded from `.env`, not passed inline in shell commands. Inlining exposes secrets in shell history and process listings.

**Correct approach — use `set -a` to export all variables, then run:**
```bash
set -a && source .env && set +a && uv run dbt run --select <model>
```

Note: plain `source .env` sets variables but does not export them to child processes. Always use `set -a` / `set +a` to ensure dbt receives them.

**Never do this:**
```bash
DUNE_API_KEY=abc123 uv run dbt run ...   # exposes key in command history
```

**If .env doesn't exist yet**, copy from the template:
```bash
cp .env.example .env
# Then fill in real values in .env
```

### 4. Verify DUNE_TEAM_NAME matches your exact Dune team slug

The `DUNE_TEAM_NAME` in `.env` must exactly match your team's slug in Dune (visible in app.dune.com → team settings). An incorrect team name causes a `Schema does not exist` error — the schema is derived from the team name.

### 5. Test connection before running models

```bash
set -a && source .env && set +a && uv run dbt debug
```

You should see: `All checks passed!`

---

## Running Models

Factory addresses are stored as inline `VALUES()` in `models/utils/factory_addresses/dim_*_factory_addresses.sql` views — **no seed upload required or ever needed**. The views compile inline into each staging model query at run time.

```bash
# Single model (recommended for first test):
set -a && source .env && set +a && uv run dbt run --select <model_name>

# DEX staging models only:
set -a && source .env && set +a && uv run dbt run --select staging.dex

# All non-view models (what prod workflow runs):
set -a && source .env && set +a && uv run dbt run --exclude config.materialized:view
```

> ### NEVER RUN `--full-refresh` UNLESS EXPLICITLY INSTRUCTED
> Full refresh on any staging model scans **all history** of the underlying raw blockchain table (`evms.logs`, `evms.transactions`, `evms.traces`, or equivalent) from that contract's `min_block_number` — potentially years of data across dozens of chains. This is the single most expensive operation in this project.
>
> - **Never** run it by default, as part of a routine fix, or out of caution
> - **Only** run it when a new factory address has been added that requires a historical backfill
> - `dbt_deploy.yml` triggers `--full-refresh` automatically on any code-modified model when merging to main — do not merge staging SQL changes unless a full backfill is intentional
> - `dbt_ci.yml` is disabled by default — keep it disabled; enabling it runs `--full-refresh` on every PR that touches staging files

**Never run `dbt seed`.** There are no seeds in this project. Factory addresses live in `models/utils/factory_addresses/` as SQL views.

---

## Materialization Strategy

Follow these rules for every model in this project:

| Layer | Rule | Reason |
|-------|------|--------|
| `evms.logs` source queries (staging) | Always `incremental` (delete+insert, 3-day lookback) | Full-refresh scans years of raw data — too expensive |
| Intermediate models | `view` by default | Views on small staging tables are cheap; no schedule entry needed |
| Intermediate models (promote to `incremental`) | Only if: consumed by 3+ downstream models **AND** does heavy aggregation | Otherwise keep as view |
| Marts | `table` by default | Stores final results; downstream consumers scan the table, not raw logs |
| Utils / dims | Always `view` | Reference data, no compute cost |

**Dependency ordering is automatic.** dbt's DAG ensures staging always runs before intermediate before marts. Never add per-layer scheduling logic to GitHub Actions workflows — the `--exclude config.materialized:view` selector handles everything.

**Promoting an intermediate from view → table:** Just change `materialized = 'incremental'` in the model config. It will automatically be included in the next `dbt_prod.yml` run — no workflow changes needed.

### Querying models in Dune

| Target | Schema | Query syntax |
|--------|--------|--------------|
| Dev (`--target dev`) | `<DUNE_TEAM_NAME>__tmp_` | `SELECT * FROM dune.<team>__tmp_.<model> LIMIT 100` |
| Prod (`--target prod`) | `<DUNE_TEAM_NAME>` | `SELECT * FROM dune.<team>.<model> LIMIT 100` |

### Credit risk reference

| Trigger | Risk | Notes |
|---------|------|-------|
| Daily `dbt_prod.yml` (`--select staging.dex`) | Low | Incremental 3-day lookback only |
| `dbt_deploy.yml` on merge to main | **HIGH for staging models** | Runs `--full-refresh` on any modified model — merging a change to a staging SQL file triggers a full historical scan of `evms.logs`. Only merge staging SQL changes when a full backfill is intentional. |
| Manual `--full-refresh` | Controlled | Already documented above |

> **`dbt_ci.yml` (PR validation) is disabled by default — keep it disabled.** If enabled, it runs `--full-refresh` on modified models on every PR, which burns significant credits on staging files.

---

## Updating Factory Addresses

> **Rule: Never refresh factory addresses as part of a SQL or dbt model job.** Factory address refresh is handled exclusively by `jobs/refresh_*.md` jobs, run on a monthly schedule via `.github/workflows/refresh_factory_addresses.yml`. When building or running any model, treat the addresses in `dim_dex_factory_addresses.sql` as current.

Factory addresses live in `models/utils/factory_addresses/dim_dex_factory_addresses.sql` as inline `VALUES()`. There are two update paths:

### Primary: Agent-driven (run a job)

Run the relevant refresh job (e.g. `jobs/refresh_uniswap_v3_deployments.md`). The agent reads the current SQL file, fetches official docs, and adds new `VALUES` rows directly. Then commit the changed file.

Factory address refresh jobs run rarely — only when new chain deployments are announced. They are **separate from dbt model jobs**. When creating or updating a staging model, do not include an address refresh step — assume the addresses are already current.

### Secondary: Bulk import from a spreadsheet

If you need to import many addresses at once from a Google Sheet or CSV, use the sync script:

```bash
set -a && source .env && set +a && uv run python scripts/sync_factory_addresses.py --url "$FACTORY_ADDRESSES_SHEET_URL"
```

This regenerates the entire `dim_dex_factory_addresses.sql` from the sheet. Commit the result.

See `jobs/GOOGLE_SHEET_WORKFLOW.md` for full documentation of this pattern (useful for other dim/labeling tables too).

---

## Adding a New Chain or DEX

Both scenarios require `--full-refresh` on `stg_dex_pool_token_transfers` to backfill
historical transfers for newly covered pools. This is expected — it drops and rebuilds the
transfer table (~22 minutes). Log each run to `docs/run_log.csv` from `target/run_results.json`
before running the next command.

### Scenario A: New chain for an existing DEX

Triggered when a protocol you already track (e.g. SushiSwap) deploys on a new blockchain,
and you've added its factory address to `dim_dex_factory_addresses.sql`.

**Only full-refresh the staging models whose factory addresses changed.** If only SushiSwap
added a new chain, you don't need to touch Uniswap or PancakeSwap staging.

```bash
# Step 1: Full-refresh the affected protocol's pool creation staging model(s).
# This rescans all history for that protocol across all chains — including the new one.
set -a && source .env && set +a && uv run dbt run \
  --select stg_sushiswap_v2_pool_created stg_sushiswap_v3_pool_created \
  --full-refresh

# → Read target/run_results.json, append to docs/run_log.csv before continuing.

# Step 2: Full-refresh the token transfers table.
# Required because the new chain's pools have no historical transfers loaded yet.
set -a && source .env && set +a && uv run dbt run \
  --select stg_dex_pool_token_transfers \
  --full-refresh

# → Read target/run_results.json, append to docs/run_log.csv before continuing.

# Step 3: Rebuild the mart. Always a full rebuild — no --full-refresh flag needed.
set -a && source .env && set +a && uv run dbt run \
  --select fact_dex_pool_token_balance

# → Read target/run_results.json, append to docs/run_log.csv.
```

### Scenario B: New DEX protocol

Triggered when adding a brand-new protocol (new staging model, new factory addresses,
new UNION ALL branch in `int_dex_pool_created`).

**Pre-run checklist (before any dbt run):**
1. Create `models/staging/dex/{protocol}/stg_{protocol}_v2_pool_created.sql` — follow `jobs/NEW_MODEL_CHECKLIST.md`
2. Add factory address rows to `models/utils/factory_addresses/dim_dex_factory_addresses.sql`
3. Add the new model as a UNION ALL branch in `models/intermediate/dex/int_dex_pool_created.sql`
4. Update `accepted_values` for `protocol` in `models/intermediate/dex/_schema.yml` to include the new protocol name
5. Add a `_schema.yml` entry for the new staging model in its subfolder

```bash
# Step 1: Run the new pool creation staging model.
# It's a new table (doesn't exist yet), so is_incremental() = false → full history
# loads automatically. No --full-refresh flag needed.
set -a && source .env && set +a && uv run dbt run \
  --select stg_{protocol}_v2_pool_created   # add other versions if applicable

# → Read target/run_results.json, append to docs/run_log.csv before continuing.

# Step 2: Full-refresh the token transfers table.
# The new protocol's pools weren't in the previous pool_tokens whitelist, so their
# historical transfers were never loaded.
set -a && source .env && set +a && uv run dbt run \
  --select stg_dex_pool_token_transfers \
  --full-refresh

# → Read target/run_results.json, append to docs/run_log.csv before continuing.

# Step 3: Rebuild the mart.
set -a && source .env && set +a && uv run dbt run \
  --select fact_dex_pool_token_balance

# → Read target/run_results.json, append to docs/run_log.csv.
```

> **Why --full-refresh on transfers every time?**
> `stg_dex_pool_token_transfers` is incremental with a 3-day lookback. Without `--full-refresh`,
> it only scans the last 3 days of `tokens.transfers` — missing all historical data for newly
> added pools. There is no incremental workaround; accept the ~22-minute rebuild cost.

---

## dbt Schema YAML Conventions

### accepted_values test format (dbt 1.10+)

Always nest `values` under `arguments:`. The flat form is deprecated and causes warnings:

```yaml
# CORRECT — use this:
- accepted_values:
    arguments:
      values: ['foo', 'bar']

# DEPRECATED — do not use:
- accepted_values:
    values: ['foo', 'bar']
```

`not_null` takes no arguments and needs no wrapper.

### Trino-specific SQL patterns

- `QUALIFY <condition>` filters rows after a window function without a wrapper CTE — supported in Trino. Preferred over wrapping in a subquery.
  ```sql
  select ..., sum(...) over (...) as balance
  from ...
  qualify balance > 0
  ```

### Signed amount convention (transfer models)

In transfer staging models (`stg_dex_pool_token_transfers` and future equivalents):
- `amount`: **signed** — positive for inflow, negative for outflow
- `amount_usd`: **signed** — same sign convention
- `amount_raw`: **always positive** — raw on-chain integer, never negated. Only `amount` and `amount_usd` carry the sign.

### Staging folder structure

Protocol-specific staging models live in `models/staging/dex/{protocol}/`, each with their own `_schema.yml`.
Cross-protocol models (e.g. `stg_dex_pool_token_transfers`) stay in `models/staging/dex/` root.
New protocols: create a new subfolder, don't add to the root.

---

## Run Documentation

> **Update the CSV immediately after each run — `target/run_results.json` is overwritten on every `dbt run`.**
>
> **Never construct log rows from terminal output.** Terminal output does not include `query_id`. Always read `target/run_results.json` as the sole source of truth. If another `dbt run` executes before the log is updated, the file is gone and the query_id is unrecoverable locally (though it may still be visible in app.dune.com/settings/billing).

After every successful `dbt run`, append rows to `docs/run_log.csv`.

### How to populate the log

All data comes from `target/run_results.json` — read it **before** running any other dbt command:

| CSV column | Source |
|------------|--------|
| `run_date` | `metadata.invocation_started_at` (date only, UTC) |
| `run_timestamp` | `metadata.invocation_started_at` (full ISO, UTC) |
| `target` | the `--target` flag used (dev or prod) |
| `vars` | the `--vars` JSON passed to dbt, or empty string if none |
| `model` | `results[n].unique_id` stripped of `model.<profile>.` prefix |
| `query_id` | `results[n].adapter_response.query_id` |
| `operation` | `results[n].adapter_response._message` |
| `rows_affected` | `results[n].adapter_response.rows_affected` |
| `duration_seconds` | `results[n].execution_time` (round to 2dp) |
| `credit_cost` | Leave blank — user fills manually from app.dune.com/settings/billing |
| `notes` | Brief description of the run context (e.g. "first load arbitrum only") |

Only append rows for successful results (`status = "success"`). Skip errors and skips. Log **every** model dbt executed — including utility views (e.g. `dim_dex_factory_addresses`) if they appear in `run_results.json` because the run used a `+` prefix or explicitly selected them. Do not filter by model type.

---

## Project Overview

See `SETUP_FOR_NEW_TEAMS.md` for full setup instructions.
See `jobs/NEW_MODEL_CHECKLIST.md` for how to add a new protocol model.
See `jobs/README.md` for a list of all scheduled agent jobs.
