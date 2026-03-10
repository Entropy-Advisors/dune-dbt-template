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

## Project Overview

See `SETUP_FOR_NEW_TEAMS.md` for full setup instructions.
See `jobs/NEW_MODEL_CHECKLIST.md` for how to add a new protocol model.
See `jobs/README.md` for a list of all scheduled agent jobs.
