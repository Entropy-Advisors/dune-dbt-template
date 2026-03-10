# Google Sheet Sync Workflow

## When to use this

The Google Sheet sync pattern is a **bulk import tool** — useful when:

- You have many addresses or labels to manage in a spreadsheet UI
- A table is human-maintained (not agent-maintained)
- You're bootstrapping a new dim table with data from an existing spreadsheet
- You want non-engineers to be able to contribute data without touching SQL

For tables that are agent-maintained (e.g. factory addresses from official protocol docs), the agent writes directly to the SQL file. The Google Sheet is not needed.

## How it works

1. A Google Sheet (or any public CSV) is the source of truth
2. `scripts/sync_factory_addresses.py` fetches the sheet, validates rows, and regenerates the SQL `dim_*` view file
3. The script is committed — the dim view becomes a Jinja-compiled inline `VALUES()` view in Dune

## Step-by-step: publish a Google Sheet as CSV

1. Open the Google Sheet
2. File → Share → Publish to web
3. Select the sheet → set format to **CSV** → click Publish
4. Copy the URL (looks like `https://docs.google.com/spreadsheets/d/e/2PACX-.../pub?output=csv`)

Store the URL in `.env` as `FACTORY_ADDRESSES_SHEET_URL` for local use.

## Running the sync script

```bash
set -a && source .env && set +a && uv run python scripts/sync_factory_addresses.py --url "$FACTORY_ADDRESSES_SHEET_URL"
```

Dry run (print output, don't write files):

```bash
set -a && source .env && set +a && uv run python scripts/sync_factory_addresses.py --url "$FACTORY_ADDRESSES_SHEET_URL" --dry-run
```

Then commit the changed `dim_*.sql` file.

## Required sheet columns

| protocol | version | blockchain | contract_address | min_block_number |
|---|---|---|---|---|
| uniswap | 2 | ethereum | 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f | 10008355 |
| camelot | 3 | arbitrum | 0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B | 101163738 |

Rules enforced by the script:
- `contract_address` must start with `0x`
- `min_block_number` must be a positive integer (never 0)
- No duplicate `(protocol, version, blockchain, contract_address)` pairs
- Rows missing required fields are skipped with a warning

## Extending the pattern to a new dim table

The sync script has a `FILE_MAP` that maps `(protocol, version)` groups to output SQL files. To add a new dim table:

1. Add rows to the Google Sheet (or a new sheet tab)
2. Add a new `dim_<protocol>_factory_addresses.sql` file in `models/utils/factory_addresses/`
3. Add the mapping to `FILE_MAP` in `scripts/sync_factory_addresses.py`
4. Run the sync script

If the new table has a different schema (e.g. a labeling table with different columns), you'll need to extend the script's SQL template accordingly.

## GitHub Actions

The sync workflow is at `.github/workflows/sync_factory_addresses.yml` — manual trigger only (`workflow_dispatch`). Run it from the GitHub Actions UI after updating the Google Sheet. It commits the regenerated SQL file automatically.
