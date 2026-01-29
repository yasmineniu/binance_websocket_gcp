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

## Performance Optimization (High Frequency)
To handle the immense volume of Binance L2 updates (thousands/sec) on small cloud instances, the following optimizations were applied:

### A. Throughput Tuning

1. **Batch Publishing**:
    - `BatchSettings`: Buffer up to **2500 messages** or **100ms** latency.
    - `publish_batch()`: Python-side optimization to reduce loop overhead.
2. **Serialization**: Replaced json with **`orjson`** (Rust-based, ~10x faster).
3. **Event Loop**: Switched to **`uvloop`** for high-performance AsyncIO.
4. removing logger to reduce the IO

### B. Deep Update Filtering (Smart Filter)

- **Logic**: High-frequency updates often occur deep in the order book (e.g., price level 500).
- **Optimization**: In l2_event.py, we check if the update price exists in our local **Top 30** book.
    - If `Yes` -> Publish.
    - If `No` -> **Drop** (Ignore).
- **Impact**:
    - Reduces Pub/Sub volume by ~90%.
    - **Sequence Gaps**: You _will_ see gaps in the sequence ID check. **This is expected behavior.** We are intentionally skipping updates for deep levels, so the sequence IDs will appear roughly consecutive but with jumps.



## Test Result from run_dq_checks.sh on local:
<img width="627" height="324" alt="image" src="https://github.com/user-attachments/assets/6db52de2-4c08-48b9-9dcd-0030921e3778" />


## Test Result from GCP running on GCP:
e2-micro (2 vCPUs, 1 GB Memory)
<img width="833" height="337" alt="image" src="https://github.com/user-attachments/assets/a6b55008-1d79-4e32-9ba4-b335f8d194f4" />
