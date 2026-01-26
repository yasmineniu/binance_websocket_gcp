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

## Data Flow

1.  **Connect**: `feeds/binance_feed.py` connects to Binance WebSocket.
2.  **Process**:
    - **L2**: Buffers deltas and snapshots.
    - **Ticker/Trades**: deserializes and formats data.
3.  **Publish**: `util_publish/emit.py` pushes JSON messages to Pub/Sub topics (e.g., `crypto.binance.l2`).
