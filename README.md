# Binance WebSocket to GCP Data Pipeline

This project implements a real-time cryptocurrency data ingestion pipeline. It connects to the **Binance** WebSocket feeds (Ticker, Trades, L2 Order Book) and publishes the data to **Google Cloud Pub/Sub** for downstream processing (e.g., BigQuery ingestion).

## Features

- **Multi-Channel Support**: Ingests `TICKER`, `TRADES`, and `L2_BOOK` data.
- **Robust L2 Handling**: Manages L2 Order Book snapshots and deltas locally before publishing.
- **GCP Integration**: Publishes data strictly typed to Google Cloud Pub/Sub topics.
- **Docker Ready**: Includes `requirements.txt` for easy deployment.

## Project Structure

```
.
├── feeds/              # Python scripts for CryptoFeed handlers
│   └── binance_feed.py # Main entry point for Binance feed
├── models/             # Data models for event serialization
├── scripts/            # Helper scripts for setup and maintenance
├── util_publish/       # Google Pub/Sub publishing utility
├── constant.py         # Configuration constants
└── requirements.txt    # Python dependencies
```

## Setup & Usage

### Prerequisites

- Python 3.10+
- Google Cloud Platform account with Pub/Sub enabled.
- GCP Credentials configured (e.g., via `GOOGLE_APPLICATION_CREDENTIALS`).

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yasmineniu/binance_websocket_gcp.git
    cd binance_websocket_gcp
    ```

2.  **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

3.  **Configure Environment**:
    Ensure your GCP project ID and credentials are set up. Update `constant.py` or environment variables if necessary.

### Running the Feed

Run the main feed script to start ingesting data:

```bash
python3 feeds/binance_feed.py
```

### Scripts

- `scripts/setup_gcp_resources.sh`: Automates the creation of Pub/Sub topics and BigQuery datasets.
- `scripts/clear_all_tables.sh`: (Caution) Clears data from BigQuery tables.
- `scripts/run_dq_checks.sh`: Runs BigQuery SQL checks to validate data quality.

### Data Quality Checks

The `run_dq_checks.sh` script performs the following validations:

1.  **Latency Check**:
    - Calculates average and p99 latency between `event_ts` and `receipt_ts`.
    - Helps identify network delays or clock synchronization issues.

2.  **Sequence Gap Check**:
    - Detects missing `seq_id` in L2 data.
    - Identifies potential packet loss in the WebSocket feed.

3.  **Stream Alignment**:
    - Compares the freshness of L2 vs. Trade data.
    - Detects "frozen" streams where one feed stops updating while the other continues.

## Data Flow

1.  **Connect**: `feeds/binance_feed.py` connects to Binance WebSocket.
2.  **Process**:
    - **L2**: Buffers deltas and snapshots.
    - **Ticker/Trades**: deserializes and formats data.
3.  **Publish**: `util_publish/emit.py` pushes JSON messages to Pub/Sub topics (e.g., `crypto.binance.l2`).


## Test Result from run_dq_checks.sh on local:
fangxinniu@Fangxins-MacBook-Air stage_a % ./run_dq_checks.sh 
=== 1. Latency Check (Last 1 Hour) ===
+----------+----------+-------+--------------------+----------------+
| exchange |  symbol  | count |   avg_latency_ms   | p99_latency_ms |
+----------+----------+-------+--------------------+----------------+
| binance  | BTC-USDT |  1011 | -76.89713155291791 |              0 |
| binance  | ETH-USDT |  1079 | -78.42354031510658 |              0 |
+----------+----------+-------+--------------------+----------------+
=== 2. Sequence Gap Check (Potential Packet Loss) ===
+----------+----------+------------+--------------+--------------+
| exchange |  symbol  | gap_events | min_gap_size | max_gap_size |
+----------+----------+------------+--------------+--------------+
| binance  | BTC-USDT |         69 |           10 |          159 |
| binance  | ETH-USDT |         68 |            9 |          553 |
+----------+----------+------------+--------------+--------------+
=== 3. Stream Alignment (Trades vs L2) ===
+----------+----------+---------------------+---------------------+--------+
| exchange |  symbol  |      max_l2_ts      |    max_trade_ts     | lag_ms |
+----------+----------+---------------------+---------------------+--------+
| binance  | ETH-USDT | 2026-01-29 06:00:33 | 2026-01-29 06:00:32 |    997 |
| binance  | BTC-USDT | 2026-01-29 06:00:33 | 2026-01-29 06:00:33 |    492 |
+----------+----------+---------------------+---------------------+--------+


## Test Result from GCP running on GCP:
e2-micro (2 vCPUs, 1 GB Memory)
(venv) niujasmine01@instance-20260126-133029:~/binance_websocket_gcp/scripts$ ./run_dq_checks.sh 
=== 1. Latency Check (Last 1 Hour) ===
+----------+----------+-------+-------------------+----------------+
| exchange |  symbol  | count |  avg_latency_ms   | p99_latency_ms |
+----------+----------+-------+-------------------+----------------+
| binance  | BTC-USDT |  3749 | 3.443851693785009 |             10 |
| binance  | ETH-USDT |  5214 | 5.035097813578823 |             16 |
+----------+----------+-------+-------------------+----------------+
=== 2. Sequence Gap Check (Potential Packet Loss) ===
+----------+----------+------------+--------------+--------------+
| exchange |  symbol  | gap_events | min_gap_size | max_gap_size |
+----------+----------+------------+--------------+--------------+
| binance  | BTC-USDT |        110 |            8 |         2189 |
| binance  | ETH-USDT |        109 |           10 |         2279 |
+----------+----------+------------+--------------+--------------+
=== 3. Stream Alignment (Trades vs L2) ===
+----------+----------+---------------------+---------------------+--------+
| exchange |  symbol  |      max_l2_ts      |    max_trade_ts     | lag_ms |
+----------+----------+---------------------+---------------------+--------+
| binance  | BTC-USDT | 2026-01-29 08:29:52 | 2026-01-29 08:29:52 |     66 |
| binance  | ETH-USDT | 2026-01-29 08:29:52 | 2026-01-29 08:29:52 |     -3 |
+----------+----------+---------------------+---------------------+--------+