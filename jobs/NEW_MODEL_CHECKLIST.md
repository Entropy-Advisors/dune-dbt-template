# New Protocol Model Checklist

Use this when adding a brand new DEX protocol to this project from scratch.
For refreshing existing factory address entries with new chain deployments, use the protocol-specific `refresh_*.md` job file instead.

---

## Step 1: Find Official Deployment Docs

1. Go to the protocol's official documentation site
2. Find the contracts or deployments page — look for factory contract addresses per chain
3. Cross-reference with the protocol's GitHub org — look for `deployments.json` files, deployment scripts, or chain-specific README files
4. Note every (chain, factory_address) pair found

---

## Step 2: Get the Event Signature

From the protocol's GitHub source code, find the factory contract ABI. Look for:
- `IFactory.sol`, `Factory.sol`, `IPoolFactory.sol`, or similar
- The event emitted when a new pool/pair is created

Common signatures by protocol type:
| Type | Event Signature |
|------|----------------|
| Uniswap V2 fork | `PairCreated(address indexed token0, address indexed token1, address pair, uint256)` |
| Uniswap V3 fork | `PoolCreated(address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool)` |
| Algebra Finance (e.g. Camelot V3) | `Pool(address indexed token0, address indexed token1, address pool)` |
| Other | Find in source — do not assume |

**Write down the canonical signature string** (types only, no parameter names, no `indexed` keyword):
e.g. `PairCreated(address,address,address,uint256)`

---

## Step 3: Compute topic0

topic0 = keccak256 of the canonical event signature string.

**Always use `cast keccak` first.** It is always installed in this environment (Foundry). Do not attempt Python methods unless `cast` is explicitly unavailable.

```bash
cast keccak "EventName(type,type,...)"
# e.g.
cast keccak "PairCreated(address,address,address,uint256)"
cast keccak "PoolCreated(address,address,uint24,int24,address)"
cast keccak "Pool(address,address,address)"
```

**Fallback only if `cast` is unavailable — Method B (pycryptodome):**
```bash
python3 -c "
from Crypto.Hash import keccak
k = keccak.new(digest_bits=256)
k.update(b'EventName(type,type,...)')
print('0x' + k.hexdigest())
"
```

**Fallback only if `cast` is unavailable — Method C (eth_utils):**
```bash
python3 -c "from eth_utils import keccak; print(keccak(text='EventName(type,type,...)').hex())"
```

**Cross-check on-chain (mandatory):**
1. Find any pool-creation transaction from the factory contract on the chain's block explorer
2. Open the transaction → Logs tab → find the pool creation event
3. Confirm topic[0] matches your computed hash exactly
4. If they differ, recheck your event signature — a single character mismatch changes the hash entirely

Known canonical topic0 values (pre-verified):
- `PairCreated(address,address,address,uint256)` → `0x0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9`
- `PoolCreated(address,address,uint24,int24,address)` → `0x783cca1c0412dd0d695e784568c96da2e9c22ff989357a2e8b1d9b2b4e6b7118`

---

## Step 4: Find Deployment Block Numbers

For each factory address, find the block it was deployed in. Use this priority order:

1. **Official docs** — some protocols list block numbers next to addresses
2. **GitHub** — look for `deployments.json`, `addresses.json`, or deployment scripts
3. **Block explorer** — search `"<chain> <contract_address> contract creation"` — the creation transaction shows the exact block
4. **Block explorer contract page** — the "Contract Creator" row links to the creation transaction
5. **If not found** — do NOT include the row in `dim_dex_factory_addresses.sql`. Leave it out and note it in the job file as a TODO. Do not use 0 — scanning from block 0 is extremely expensive on Dune.

---

## Step 5: Verify Dune Chain Names

Dune uses its own names for chains. For each chain in your deployment list:

1. Check https://docs.dune.com for supported chains in `evms.logs`
2. Web search `"Dune Analytics <chain name> evms"` for the correct identifier
3. If the chain is not in Dune, include the row using the chain's common name and flag it in the job file — it will silently produce no rows until Dune adds support (harmless)

Confirmed Dune chain name mappings:
- Ethereum Mainnet → `ethereum`
- Arbitrum One → `arbitrum`
- BNB Chain → `bnb`
- Polygon PoS → `polygon`
- Polygon zkEVM → `zkevm`
- Avalanche C-Chain → `avalanche_c`
- Base → `base`
- Optimism → `optimism`
- Blast → `blast`
- Zora → `zora`
- World Chain → `worldchain`
- Unichain → `unichain`
- Celo → `celo`
- Linea → `linea`
- zkSync Era → `zksync`
- opBNB → `opbnb`
- Fantom → `fantom`
- Gnosis → `gnosis`
- Arbitrum Nova → `arbitrum_nova`

---

## Step 6: Add Factory Addresses to `dim_dex_factory_addresses.sql`

> **Do NOT run a factory address refresh job here.** You already have the addresses from Steps 1–4. Refresh jobs (`jobs/refresh_*.md`) are a separate, scheduled operation run monthly via GitHub Actions. Model creation never triggers them.

Add the factory addresses you found in Step 1 directly to `models/utils/factory_addresses/dim_dex_factory_addresses.sql`:

1. Find the `-- <Protocol> V<version>` comment block for your protocol, or add a new block if the protocol doesn't exist yet
2. Add one row per (blockchain, contract_address):
   ```sql
   ('protocol', 'version', 'blockchain', 0xAddress, min_block_number),
   ```
3. Commit the updated file

Address rules:
- `min_block_number` must be a confirmed positive integer — never 0
- `contract_address` should be checksummed hex
- The same address may appear on multiple chains (CREATE2) — valid as long as `blockchain` differs
- No duplicate (protocol, version, blockchain, contract_address) tuples

---

## Step 7: Choose Materialization

Before writing the SQL model, confirm the correct materialization. Follow the project rules:

| Model type | Materialization |
|-----------|----------------|
| Staging model sourcing `evms.logs` | `incremental` (delete+insert, 3-day lookback) — **always** |
| Intermediate model (≤2 downstream consumers, light logic) | `view` (default — no config block needed) |
| Intermediate model (3+ downstream consumers AND heavy aggregation) | `incremental` |
| Mart | `table` (default — no config block needed) |
| Util / dim | `view` (default) |

**Key rule:** intermediate views are resolved inline when marts refresh — they do NOT need a separate schedule entry or `dbt run` command. Promoting an intermediate from view → incremental later requires no GitHub Actions changes.

---

## Step 8: Build the SQL Model

File: `models/staging/dex/stg_<protocol>_<version>_pool_created.sql`

**If the event matches an existing pattern** (e.g. same ABI as Uniswap V2/V3):
Copy the closest existing model and update: `alias`, `ref()` model name, `protocol` literal, `version` literal.

**If the event is different** (new ABI, different columns):
Build from the standard config + CTE structure, but change:
- `topic0` filter value
- `decode_evm_event` ABI string
- Final SELECT columns to match what the ABI decodes

Config block (same for all models):
```sql
{{
    config(
        alias = 'stg_<protocol>_<version>_pool_created',
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = ['blockchain', 'block_number', 'tx_hash'],
        properties = {
            "partitioned_by": "ARRAY['blockchain', 'block_date']"
        }
    )
}}
```

The `block_date` column must be computed in the `logs` CTE:
```sql
cast(date_trunc('day', l.block_time) as date) as block_date,
```

The `is_incremental()` lookback window goes in the `WHERE` clause of the `logs` CTE:
```sql
where
    l.topic0 = 0x<topic0_here>
    and (l.blockchain, l.contract_address) in (select blockchain, contract_address from factory_addresses)
    {%- if is_incremental() %}
    and l.block_date >= cast(now() - interval '3' day as date)
    {%- endif %}
```

The tuple `IN` filter is not redundant with the INNER JOIN — it gives Trino an explicit predicate to push down to the Parquet scan level (partition pruning on `blockchain`, row-group skipping on `contract_address`). The JOIN alone applies after pages are read; the WHERE predicate applies before. Use the tuple form (not two separate `IN` clauses) so only valid `(blockchain, contract_address)` pairs from the factory table are matched.

**Why 3 days, not 1:**
- **Reorg protection** — blockchain reorganizations can invalidate recent blocks. `delete+insert` on 3 days deletes and re-writes those rows with the correct data. A 1-day window risks keeping stale data from a reorged block.
- **Missed run recovery** — if the scheduler fails one day (GitHub Actions outage, rate limit), the next run automatically backfills the gap. With a 1-day window, a missed run creates a permanent data gap.
- **Late Dune indexing** — Dune's ingestion of `evms.logs` can occasionally lag; 3 days catches anything delayed in indexing.

**First run behaviour** — `is_incremental()` evaluates to `false` when the target table does not yet exist. The lookback line is omitted, and dbt scans all history from each factory's `min_block_number`. This is expected and correct. Every subsequent run uses the 3-day window and is cheap.

**Cost trade-off** — scanning 3 days vs 1 day per daily run costs ~3× more per run in absolute terms, but since each daily partition is a tiny fraction of total `evms.logs` history, the absolute credit cost remains negligible. The correctness guarantees are worth it.

---

## Step 9: Update `models/staging/dex/_schema.yml`

Append a new model entry. At minimum include:
- `name`, `description`
- `not_null` tests on: `blockchain`, `contract_address`, `protocol`, `version`, `block_date`, `block_time`, `block_number`, `tx_hash`, `pool`, `token0`, `token1`
- `accepted_values` tests on `protocol` and `version`
- For V3 models: also document `fee` and `tick_spacing`

---

## Step 10: Create the Job File

File: `jobs/refresh_<protocol>_<version>_deployments.md`

Keep it lean — protocol-specific facts only. Structure:
- **Goal**: one sentence
- **Suggested Frequency**: Monthly
- **Source of Truth**: official docs URL
- **Target File**: `models/utils/factory_addresses/dim_dex_factory_addresses.sql`
- **What to Do**: numbered steps (read `dim_dex_factory_addresses.sql` → fetch official list → compare → add missing rows)
- **ABI**: event signature, topic0, cross-contamination warning (list all protocols that share the same topic0)
- **Validation Rules**: no deletes, no duplicates, positive integer block numbers only
- **Output / Report**: what to report after completion
- **Context**: one paragraph on how the factory address view powers the staging model

For methodology on verifying ABI and computing topic0, refer back to this checklist.

---

## Step 11: Update `jobs/README.md`

Add a row to the Job Index table:
```
| `refresh_<protocol>_<version>_deployments.md` | Monthly | Checks for new <Protocol> <Version> factory deployments and adds them to `dim_dex_factory_addresses.sql` |
```

---

## Cross-Contamination Reference

Protocols that share topic0 (same ABI, cannot distinguish by log alone — must verify source):

**V2 forks** (topic0 `0x0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9`):
- Uniswap V2, SushiSwap V2, PancakeSwap V2, GammaSwap (DeltaSwap), Camelot V2, and any other Uniswap V2 fork

**V3 forks** (topic0 `0x783cca1c0412dd0d695e784568c96da2e9c22ff989357a2e8b1d9b2b4e6b7118`):
- Uniswap V3, SushiSwap V3, PancakeSwap V3, and any other Uniswap V3 fork

**Algebra Finance AMMs** (topic0 `0x91ccaa7a278130b65168c3a0c8d3bcae84cf5e43704342bd3ec0b59e59c036db` — verify on-chain):
- Camelot V3, and any other Algebra Finance V1.9 deployment
