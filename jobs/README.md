# Agent Jobs

This directory contains structured job definition files for AI agent tasks. Each file defines a recurring, repeatable operation that any team member can trigger by instructing an AI agent (e.g. Claude Code) to execute it.

## What is a Job?

A job is a markdown file that describes:
- **Goal** — what the agent should accomplish
- **Inputs** — where to find current data (`dim_dex_factory_addresses.sql`, GitHub repos, etc.)
- **Outputs** — which files to edit and in what format
- **Rules** — constraints the agent must respect (no deletions, no duplicates, etc.)
- **Verification** — how to confirm the result is correct

Jobs are designed to be self-contained. An agent reading the file should have everything it needs to complete the task without asking follow-up questions.

## How to Run a Job

Open Claude Code in this repository and say:

```
Run the job at jobs/<job-filename>.md
```

The agent will:
1. Read the job file
2. Gather any external data specified (GitHub, docs, etc.)
3. Read the target file(s) in this repo
4. Make the required edits
5. Report what changed and why

Review the git diff, then commit if the changes look correct.

## Scheduling

Factory address refresh jobs run automatically on the **1st of each month** via `.github/workflows/refresh_factory_addresses.yml`. The workflow invokes Claude Code to run `refresh_all_factory_addresses.md`, which executes all 9 protocol refresh jobs in sequence.

Individual jobs can still be run manually at any time (e.g. after a protocol announces a new chain deployment). See "How to Run a Job" above.

**Factory address refresh is completely separate from dbt model jobs.** SQL/dbt model jobs never refresh factory addresses — they read `dim_dex_factory_addresses.sql` as-is.

**Required GitHub Actions secret:** `ANTHROPIC_API_KEY` must be set in the repo's Actions secrets for the scheduled workflow to run.

## Job Index

| File | Frequency | What it does |
|------|-----------|-------------|
| `refresh_all_factory_addresses.md` | Monthly (via GH Actions) | Runs all 9 protocol refresh jobs in sequence — this is what the scheduler triggers |
| `refresh_sushiswap_v2_deployments.md` | Monthly | Checks for new SushiSwap V2 factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_sushiswap_v3_deployments.md` | Monthly | Checks for new SushiSwap V3 factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_uniswap_v2_deployments.md` | Monthly | Checks for new Uniswap V2 factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_uniswap_v3_deployments.md` | Monthly | Checks for new Uniswap V3 factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_uniswap_v4_deployments.md` | Monthly | Checks for new Uniswap V4 PoolManager deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_pancakeswap_v2_deployments.md` | Monthly | Checks for new PancakeSwap V2 factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_pancakeswap_v3_deployments.md` | Monthly | Checks for new PancakeSwap V3 factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_gammaswap_deployments.md` | Monthly | Checks for new GammaSwap factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_camelot_v2_deployments.md` | Monthly | Checks for new Camelot V2 factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_camelot_v3_deployments.md` | Monthly | Checks for new Camelot V3 (Algebra) factory deployments and adds them to `dim_dex_factory_addresses.sql` |
| `refresh_curve_deployments.md` | Monthly | Checks for new Curve Finance factory deployments (TwoCrypto NG, Tricrypto NG, StableSwap NG, Legacy) and adds them to `dim_dex_factory_addresses.sql` |
| `NEW_TOKEN_CHAIN_CHECKLIST.md` | On demand | Add a new chain to the token mint/burn supply pipeline |

## Adding a New Job

Copy an existing job file as a template and update:
- The goal/protocol name
- The external source URL
- The protocol/version/blockchain to add in `dim_dex_factory_addresses.sql`
- The contract addresses / ABI / topic0 if relevant
- Any protocol-specific validation rules
