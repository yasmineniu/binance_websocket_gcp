#!/bin/bash
set -e

PROJECT_ID="cryptofeed-480903"
DATASET="cryptofeed"

# --- OKX Trades ---
TABLE_TRADES="okx_trades"
TOPIC_TRADES="crypto.okx.trades"
SUBSCRIPTION_TRADES="crypto.okx.trades.bq"

echo "Creating BigQuery table: $DATASET.$TABLE_TRADES"
bq mk --table \
  --schema "exchange:STRING,symbol:STRING,side:STRING,amount:FLOAT,price:FLOAT,id:STRING,type:STRING,event_ts:TIMESTAMP,receipt_ts:TIMESTAMP,ingest_ts:TIMESTAMP" \
  --time_partitioning_field event_ts \
  --time_partitioning_type DAY \
  --clustering_fields "exchange,symbol" \
  "$PROJECT_ID:$DATASET.$TABLE_TRADES" || echo "Table $TABLE_TRADES already exists"

echo "Creating Pub/Sub topic: $TOPIC_TRADES"
gcloud pubsub topics create $TOPIC_TRADES --project=$PROJECT_ID || echo "Topic $TOPIC_TRADES already exists"

echo "Creating Pub/Sub subscription for Trades"
gcloud pubsub subscriptions create $SUBSCRIPTION_TRADES \
  --topic=$TOPIC_TRADES \
  --project=$PROJECT_ID \
  --bigquery-table=$PROJECT_ID:$DATASET.$TABLE_TRADES \
  --use-table-schema \
  --drop-unknown-fields || echo "Subscription $SUBSCRIPTION_TRADES already exists"

# --- L2 Book ---
TABLE_L2="okx_l2_book"
TOPIC_L2="crypto.okx.l2"
SUBSCRIPTION_L2="crypto.okx.l2.bq"

echo "Creating BigQuery table: $DATASET.$TABLE_L2"
bq mk --table \
  --schema "exchange:STRING,symbol:STRING,side:STRING,price:FLOAT,amount:FLOAT,checksum:STRING,seq_id:INTEGER,is_snapshot:BOOLEAN,type:STRING,event_ts:TIMESTAMP,receipt_ts:TIMESTAMP,ingest_ts:TIMESTAMP" \
  --time_partitioning_field event_ts \
  --time_partitioning_type DAY \
  --clustering_fields "exchange,symbol" \
  $PROJECT_ID:$DATASET.$TABLE_L2 || echo "Table $TABLE_L2 already exists"

echo "Creating Pub/Sub topic: $TOPIC_L2"
gcloud pubsub topics create $TOPIC_L2 --project=$PROJECT_ID || echo "Topic $TOPIC_L2 already exists"

echo "Creating Pub/Sub subscription for L2"
gcloud pubsub subscriptions create $SUBSCRIPTION_L2 \
  --topic=$TOPIC_L2 \
  --project=$PROJECT_ID \
  --bigquery-table=$PROJECT_ID:$DATASET.$TABLE_L2 \
  --use-table-schema \
  --drop-unknown-fields || echo "Subscription $SUBSCRIPTION_L2 already exists"


# --- Ticker ---
TABLE_TICKER="okx_ticker"
TOPIC_TICKER="crypto.okx.ticker"
SUBSCRIPTION_TICKER="crypto.okx.ticker.bq"

echo "Creating BigQuery table: $DATASET.$TABLE_TICKER"
bq mk --table \
  --schema "exchange:STRING,symbol:STRING,bid:FLOAT,ask:FLOAT,last:FLOAT,event_ts:TIMESTAMP,receipt_ts:TIMESTAMP,ingest_ts:TIMESTAMP" \
  --time_partitioning_field event_ts \
  --time_partitioning_type DAY \
  --clustering_fields "exchange,symbol" \
  $PROJECT_ID:$DATASET.$TABLE_TICKER || echo "Table $TABLE_TICKER already exists"

echo "Creating Pub/Sub topic: $TOPIC_TICKER"
gcloud pubsub topics create $TOPIC_TICKER --project=$PROJECT_ID || echo "Topic $TOPIC_TICKER already exists"

echo "Creating Pub/Sub subscription for Ticker"
gcloud pubsub subscriptions create $SUBSCRIPTION_TICKER \
  --topic=$TOPIC_TICKER \
  --project=$PROJECT_ID \
  --bigquery-table=$PROJECT_ID:$DATASET.$TABLE_TICKER \
  --use-table-schema \
  --drop-unknown-fields || echo "Subscription $SUBSCRIPTION_TICKER already exists"

# --- Factors ---
TABLE_FACTORS="okx_factors"
TOPIC_FACTORS="crypto.okx.factors"
SUBSCRIPTION_FACTORS="crypto.okx.factors.bq"

echo "Creating BigQuery table: $DATASET.$TABLE_FACTORS"
bq mk --table \
  --schema "exchange:STRING,symbol:STRING,mid_price:FLOAT,spread:FLOAT,imbalance_5:FLOAT,best_bid:FLOAT,best_ask:FLOAT,checksum:STRING,event_ts:TIMESTAMP,receipt_ts:TIMESTAMP,ingest_ts:TIMESTAMP" \
  --time_partitioning_field event_ts \
  --time_partitioning_type DAY \
  --clustering_fields "exchange,symbol" \
  $PROJECT_ID:$DATASET.$TABLE_FACTORS || echo "Table $TABLE_FACTORS already exists"

echo "Creating Pub/Sub topic: $TOPIC_FACTORS"
gcloud pubsub topics create $TOPIC_FACTORS --project=$PROJECT_ID || echo "Topic $TOPIC_FACTORS already exists"

echo "Creating Pub/Sub subscription for Factors"
gcloud pubsub subscriptions create $SUBSCRIPTION_FACTORS \
  --topic=$TOPIC_FACTORS \
  --project=$PROJECT_ID \
  --bigquery-table=$PROJECT_ID:$DATASET.$TABLE_FACTORS \
  --use-table-schema \
  --drop-unknown-fields || echo "Subscription $SUBSCRIPTION_FACTORS already exists"

# ==========================================
# BINANCE RESOURCES
# ==========================================

TOPIC_BIN_TRADES="crypto.binance.trades"
TOPIC_BIN_L2="crypto.binance.l2"
TOPIC_BIN_TICKER="crypto.binance.ticker"
TOPIC_BIN_FACTORS="crypto.binance.factors"

TABLE_BIN_TRADES="binance_trades"
TABLE_BIN_L2="binance_l2_book"
TABLE_BIN_TICKER="binance_ticker"
TABLE_BIN_FACTORS="binance_factors"

# --- Binance Trades ---
echo "Creating BigQuery table: $DATASET.$TABLE_BIN_TRADES"
bq mk --table \
  --schema "exchange:STRING,symbol:STRING,side:STRING,amount:FLOAT,price:FLOAT,id:STRING,type:STRING,event_ts:TIMESTAMP,receipt_ts:TIMESTAMP,ingest_ts:TIMESTAMP" \
  --time_partitioning_field event_ts \
  --time_partitioning_type DAY \
  --clustering_fields "exchange,symbol" \
  "$PROJECT_ID:$DATASET.$TABLE_BIN_TRADES" || echo "Table $TABLE_BIN_TRADES already exists"

echo "Creating Pub/Sub topic: $TOPIC_BIN_TRADES"
gcloud pubsub topics create $TOPIC_BIN_TRADES --project=$PROJECT_ID || echo "Topic $TOPIC_BIN_TRADES already exists"
gcloud pubsub subscriptions create "$TOPIC_BIN_TRADES.bq" --topic=$TOPIC_BIN_TRADES --project=$PROJECT_ID --bigquery-table="$PROJECT_ID:$DATASET.$TABLE_BIN_TRADES" --use-table-schema --drop-unknown-fields || echo "Subscription $TOPIC_BIN_TRADES.bq already exists"

# --- Binance L2 ---
echo "Creating BigQuery table: $DATASET.$TABLE_BIN_L2"
bq mk --table \
  --schema "exchange:STRING,symbol:STRING,side:STRING,price:FLOAT,amount:FLOAT,checksum:STRING,seq_id:INTEGER,is_snapshot:BOOLEAN,type:STRING,event_ts:TIMESTAMP,receipt_ts:TIMESTAMP,ingest_ts:TIMESTAMP" \
  --time_partitioning_field event_ts \
  --time_partitioning_type DAY \
  --clustering_fields "exchange,symbol" \
  "$PROJECT_ID:$DATASET.$TABLE_BIN_L2" || echo "Table $TABLE_BIN_L2 already exists"

echo "Creating Pub/Sub topic: $TOPIC_BIN_L2"
gcloud pubsub topics create $TOPIC_BIN_L2 --project=$PROJECT_ID || echo "Topic $TOPIC_BIN_L2 already exists"
gcloud pubsub subscriptions create "$TOPIC_BIN_L2.bq" --topic=$TOPIC_BIN_L2 --project=$PROJECT_ID --bigquery-table="$PROJECT_ID:$DATASET.$TABLE_BIN_L2" --use-table-schema --drop-unknown-fields || echo "Subscription $TOPIC_BIN_L2.bq already exists"

# --- Binance Ticker ---
echo "Creating BigQuery table: $DATASET.$TABLE_BIN_TICKER"
bq mk --table \
  --schema "exchange:STRING,symbol:STRING,bid:FLOAT,ask:FLOAT,last:FLOAT,event_ts:TIMESTAMP,receipt_ts:TIMESTAMP,ingest_ts:TIMESTAMP" \
  --time_partitioning_field event_ts \
  --time_partitioning_type DAY \
  --clustering_fields "exchange,symbol" \
  "$PROJECT_ID:$DATASET.$TABLE_BIN_TICKER" || echo "Table $TABLE_BIN_TICKER already exists"

echo "Creating Pub/Sub topic: $TOPIC_BIN_TICKER"
gcloud pubsub topics create $TOPIC_BIN_TICKER --project=$PROJECT_ID || echo "Topic $TOPIC_BIN_TICKER already exists"
gcloud pubsub subscriptions create "$TOPIC_BIN_TICKER.bq" --topic=$TOPIC_BIN_TICKER --project=$PROJECT_ID --bigquery-table="$PROJECT_ID:$DATASET.$TABLE_BIN_TICKER" --use-table-schema --drop-unknown-fields || echo "Subscription $TOPIC_BIN_TICKER.bq already exists"

# --- Binance Factors ---
echo "Creating BigQuery table: $DATASET.$TABLE_BIN_FACTORS"
bq mk --table \
  --schema "exchange:STRING,symbol:STRING,mid_price:FLOAT,spread:FLOAT,imbalance_5:FLOAT,best_bid:FLOAT,best_ask:FLOAT,checksum:STRING,event_ts:TIMESTAMP,receipt_ts:TIMESTAMP,ingest_ts:TIMESTAMP" \
  --time_partitioning_field event_ts \
  --time_partitioning_type DAY \
  --clustering_fields "exchange,symbol" \
  "$PROJECT_ID:$DATASET.$TABLE_BIN_FACTORS" || echo "Table $TABLE_BIN_FACTORS already exists"

echo "Creating Pub/Sub topic: $TOPIC_BIN_FACTORS"
gcloud pubsub topics create $TOPIC_BIN_FACTORS --project=$PROJECT_ID || echo "Topic $TOPIC_BIN_FACTORS already exists"
gcloud pubsub subscriptions create "$TOPIC_BIN_FACTORS.bq" --topic=$TOPIC_BIN_FACTORS --project=$PROJECT_ID --bigquery-table="$PROJECT_ID:$DATASET.$TABLE_BIN_FACTORS" --use-table-schema --drop-unknown-fields || echo "Subscription $TOPIC_BIN_FACTORS.bq already exists"
