# Data Model Naming Conventions

## Transaction-Level Fields

| Raw / Variant Names | Standard Name |
|---|---|
| `block_time`, `evt_block_time` | `block_time` |
| `tx_hash`, `hash`, `evt_tx_hash` | `tx_hash` |
| `block_number`, `height` | `block_number` |
| `from`, `sender` | `from` |
| `to`, `recipient` | `to` |

---

## Timeseries Grain

| Grain | Column Name |
|---|---|
| Daily | `day` |
| Hourly | `hour` |
| Minutely | `minute` |

---

## Token Denomination

| Column | Description |
|---|---|
| `amount_raw` | Non-decimal-adjusted amount |
| `amount` | Decimal-adjusted amount |
| `usd_amount` | USD value at time of event |

---

## Metrics Denomination

| Column | Description |
|---|---|
| `{metric}` | Decimal-adjusted native token amount |
| `usd_{metric}` | USD equivalent of the metric |

**Examples:**
- `volume` / `usd_volume`
- `fee` / `usd_fee`
- `interest` / `usd_interest`
- `cost_basis` / `usd_cost_basis`

---

## Address Fields

| Column | Description |
|---|---|
| `contract_address` | Token or protocol contract |
| `underlying_address` | Underlying token contract (for wrapped/vault tokens) |
| `address` | Unified naming of addresses for dim.labels (wallets, contracts, and tokens) |

---

## Cumulative vs Daily vs Rolling Fields

| Pattern | Description |
|---|---|
| `cumulative_{metric}` | Running total since inception |
| `daily_{metric}` | Value for that day only (delta) |
| `rolling_monthly_{metric}` | Month-to-date value (dynamic lookback to month start) |
| `{metric}_7d` | 7-day moving average or sum |
| `{metric}_30d` | 30-day moving average or sum |
| `{metric}_90d` | 90-day moving average or sum |
