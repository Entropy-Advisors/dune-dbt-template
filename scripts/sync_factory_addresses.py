#!/usr/bin/env python3
"""
Sync factory addresses from a Google Sheet to dim_dex_factory_addresses.sql.

Usage:
    uv run python scripts/sync_factory_addresses.py --url <google_sheets_csv_url>
    uv run python scripts/sync_factory_addresses.py --url <url> --dry-run

The Google Sheet must be published to web with public (Anyone) access.
To get the export URL from a Google Sheet:
    File → Share → Publish to web → CSV format → Copy link
    OR: https://docs.google.com/spreadsheets/d/{SHEET_ID}/export?format=csv

Expected columns (header row required):
    protocol | version | blockchain | contract_address | min_block_number

Example rows:
    uniswap     | 2         | ethereum  | 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f | 10008355
    gammaswap   | deltaswap | arbitrum  | 0xCb85E1222f715a81b8edaeB73b28182fa37cffA8 | 173467894
    camelot     | 3         | arbitrum  | 0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B | 101163738

Rules enforced:
    - contract_address must start with 0x
    - min_block_number must be a positive integer
    - No duplicate (protocol, version, blockchain, contract_address) pairs
    - Rows missing required fields are skipped with a warning
"""

import argparse
import csv
import io
import urllib.request
from collections import defaultdict
from pathlib import Path

OUTPUT_FILE = Path(__file__).parent.parent / "models" / "utils" / "factory_addresses" / "dim_dex_factory_addresses.sql"

SQL_HEADER = """\
{{
    config(
        alias = 'dim_dex_factory_addresses',
        materialized = 'view'
    )
}}

-- Single source of truth for all DEX factory contract addresses.
-- Agent jobs add rows directly (see jobs/refresh_*.md). For bulk imports from a spreadsheet, use scripts/sync_factory_addresses.py.
-- Columns: protocol, version, blockchain, contract_address, min_block_number

select *
from (
    values
"""

SQL_FOOTER = """\
) as t(protocol, version, blockchain, contract_address, min_block_number)
"""

# Known protocol/version groupings for comment headers in the output
PROTOCOL_ORDER = [
    ("uniswap",     "2"),
    ("uniswap",     "3"),
    ("sushiswap",   "2"),
    ("sushiswap",   "3"),
    ("pancakeswap", "2"),
    ("pancakeswap", "3"),
    ("gammaswap",   "deltaswap"),
    ("camelot",     "2"),
    ("camelot",     "3"),
]


def fetch_csv(url: str) -> list[dict]:
    print(f"Fetching: {url}")
    with urllib.request.urlopen(url) as response:
        content = response.read().decode("utf-8")
    reader = csv.DictReader(io.StringIO(content))
    return list(reader)



def validate_row(row: dict, line_num: int) -> bool:
    required = {"protocol", "version", "blockchain", "contract_address", "min_block_number"}
    missing = required - set(row.keys())
    if missing:
        print(f"  WARNING line {line_num}: missing columns {missing} — skipping")
        return False
    if not row["contract_address"].strip().startswith("0x"):
        print(f"  WARNING line {line_num}: contract_address '{row['contract_address']}' does not start with 0x — skipping")
        return False
    try:
        block = int(row["min_block_number"].strip())
        if block <= 0:
            raise ValueError
    except ValueError:
        print(f"  WARNING line {line_num}: min_block_number '{row['min_block_number']}' is not a positive integer — skipping")
        return False
    return True


def main():
    parser = argparse.ArgumentParser(description="Sync factory addresses from Google Sheets")
    parser.add_argument("--url", required=True, help="Google Sheets CSV export URL")
    parser.add_argument("--dry-run", action="store_true", help="Print generated SQL without writing files")
    args = parser.parse_args()

    rows = fetch_csv(args.url)
    print(f"Read {len(rows)} rows")

    # Group by (protocol, version), preserving order
    groups: dict[tuple, list] = defaultdict(list)
    seen_keys: set = set()

    for i, row in enumerate(rows, start=2):
        if not validate_row(row, i):
            continue
        protocol = row["protocol"].strip().lower()
        version  = row["version"].strip().lower()
        blockchain = row["blockchain"].strip()
        address    = row["contract_address"].strip()
        block      = int(row["min_block_number"].strip())

        dedup_key = (protocol, version, blockchain, address)
        if dedup_key in seen_keys:
            print(f"  WARNING line {i}: duplicate ({protocol}, {version}, {blockchain}, {address}) — skipping")
            continue
        seen_keys.add(dedup_key)
        groups[(protocol, version)].append((blockchain, address, block))

    # Build ordered list: known protocols first, then any unknown ones appended
    ordered_keys = [k for k in PROTOCOL_ORDER if k in groups]
    unknown_keys = [k for k in groups if k not in PROTOCOL_ORDER]
    if unknown_keys:
        print(f"  Note: unknown protocol/version groups will be appended: {unknown_keys}")
    all_keys = ordered_keys + unknown_keys

    # Generate VALUES lines
    all_value_lines = []
    for key in all_keys:
        protocol, version = key
        protocol_rows = groups[key]
        all_value_lines.append(f"\n        -- {protocol.capitalize()} V{version}")
        for blockchain, address, block in protocol_rows:
            all_value_lines.append(f"        ('{protocol}', '{version}', '{blockchain}', {address}, {block}),")

    # Remove trailing comma from last line
    if all_value_lines:
        all_value_lines[-1] = all_value_lines[-1].rstrip(",")

    sql = SQL_HEADER + "\n".join(all_value_lines) + "\n\n" + SQL_FOOTER

    if args.dry_run:
        print(f"\n--- {OUTPUT_FILE} ---\n{sql}")
    else:
        OUTPUT_FILE.write_text(sql)
        total_rows = sum(len(v) for v in groups.values())
        print(f"\nWritten: {OUTPUT_FILE}")
        print(f"  {total_rows} factory addresses across {len(all_keys)} protocol/version groups")


if __name__ == "__main__":
    main()
