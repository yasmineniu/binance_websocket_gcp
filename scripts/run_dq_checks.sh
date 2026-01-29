#!/bin/bash
set -e

PROJECT="cryptofeed-480903"
DATASET="cryptofeed"


# 1. Latency Check
# === 1. Latency Check (Last 1 Hour) ===
# +----------+----------+-------+---------------------+----------------+
# | exchange |  symbol  | count |   avg_latency_ms    | p99_latency_ms |
# +----------+----------+-------+---------------------+----------------+
# | binance  | BTC-USDT |   548 | -12.348540145985403 |             15 |
# | binance  | ETH-USDT |   935 | -10.011764705882356 |             18 |
# | okx      | BTC-USDT |  1309 |   8.530939648586715 |             32 |
# | okx      | ETH-USDT |  1821 | -25.136738056013186 |            -10 |
# +----------+----------+-------+---------------------+----------------+
# Summary: Negative values typically result from clock skew between servers. As long as P99 jitter is low, negative values are acceptable as they indicate clock offset rather than network latency.


echo "=== 1. Latency Check (Last 1 Hour) ==="
bq query --use_legacy_sql=false --format=pretty "
SELECT
    exchange,
    symbol,
    COUNT(*) as count,
    AVG(TIMESTAMP_DIFF(receipt_ts, event_ts, MILLISECOND)) as avg_latency_ms,
    APPROX_QUANTILES(TIMESTAMP_DIFF(receipt_ts, event_ts, MILLISECOND), 100)[OFFSET(99)] as p99_latency_ms
FROM (
    SELECT exchange, symbol, receipt_ts, event_ts FROM \`$PROJECT.$DATASET.okx_l2_book\`
    UNION ALL
    SELECT exchange, symbol, receipt_ts, event_ts FROM \`$PROJECT.$DATASET.binance_l2_book\`
)
WHERE receipt_ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
GROUP BY 1, 2
ORDER BY 1, 2
"

# 2. Sequence Gap Check (Packet Loss Candidate)
# === 2. Sequence Gap Check (Potential Packet Loss) ===
# +----------+----------+------------+--------------+--------------+
# | exchange |  symbol  | gap_events | min_gap_size | max_gap_size |
# +----------+----------+------------+--------------+--------------+
# | binance  | BTC-USDT |         38 |            4 |          136 |
# | binance  | ETH-USDT |         40 |            3 |          673 |
# +----------+----------+------------+--------------+--------------+
echo "=== 2. Sequence Gap Check (Potential Packet Loss) ==="
bq query --use_legacy_sql=false --format=pretty "
WITH sequenced AS (
    SELECT
        exchange,
        symbol,
        seq_id,
        event_ts,
        LAG(seq_id) OVER (PARTITION BY exchange, symbol ORDER BY event_ts) as prev_seq_id,
        LAG(event_ts) OVER (PARTITION BY exchange, symbol ORDER BY event_ts) as prev_event_ts
    FROM (
        SELECT exchange, symbol, seq_id, event_ts FROM \`$PROJECT.$DATASET.okx_l2_book\`
        UNION ALL
        SELECT exchange, symbol, seq_id, event_ts FROM \`$PROJECT.$DATASET.binance_l2_book\`
    )
    WHERE event_ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
)
SELECT
    exchange,
    symbol,
    COUNT(*) as gap_events,
    MIN(seq_id - prev_seq_id) as min_gap_size,
    MAX(seq_id - prev_seq_id) as max_gap_size
FROM sequenced
WHERE seq_id - prev_seq_id > 1
  AND TIMESTAMP_DIFF(event_ts, prev_event_ts, SECOND) < 5
  # Prevent false positives
GROUP BY 1, 2
"

# 3. Time Alignment (Freshness)
# "Two channels from the same exchange (e.g., L2 and Trades) should have roughly synchronized timestamps.
# 1. For example, l2_book has a lot of data (process ts is 10:00:05) and block the trade event loop (process ts is 10:00:00).
# 2. Detect WebSocket stalls: Sometimes network issues break the Trades connection while L2 remains active. Comparison reveals if Trades have stopped updating.
# 3. Data Alignment for Backtesting: Significant time skew between streams can lead to incorrect strategy signals (e.g., matching a 5-second old trade price with the current order book generating false arbitrage signals).
echo "=== 3. Stream Alignment (Trades vs L2) ==="
bq query --use_legacy_sql=false --format=pretty "
WITH l2_freshness AS (
    SELECT exchange, symbol, MAX(event_ts) as max_l2_ts
    FROM (
        SELECT exchange, symbol, event_ts FROM \`$PROJECT.$DATASET.okx_l2_book\`
        UNION ALL
        SELECT exchange, symbol, event_ts FROM \`$PROJECT.$DATASET.binance_l2_book\`
    )
    GROUP BY 1, 2
),
trade_freshness AS (
    SELECT exchange, symbol, MAX(event_ts) as max_trade_ts
    FROM (
        SELECT exchange, symbol, event_ts FROM \`$PROJECT.$DATASET.okx_trades\`
        UNION ALL
        SELECT exchange, symbol, event_ts FROM \`$PROJECT.$DATASET.binance_trades\`
    )
    GROUP BY 1, 2
)
SELECT
    t1.exchange,
    t1.symbol,
    t1.max_l2_ts,
    t2.max_trade_ts,
    TIMESTAMP_DIFF(t1.max_l2_ts, t2.max_trade_ts, MILLISECOND) as lag_ms
FROM l2_freshness t1
JOIN trade_freshness t2 ON t1.exchange = t2.exchange AND t1.symbol = t2.symbol
"
