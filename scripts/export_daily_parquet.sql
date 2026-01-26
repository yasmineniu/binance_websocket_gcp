-- Export L2 Data to GCS in Parquet format
-- Usage: Replace @run_date with 'YYYY-MM-DD' and @bucket_name with your bucket.

EXPORT DATA OPTIONS(
  uri='gs://@bucket_name/l2_book/dt=@run_date/l2_book_*.parquet',
  format='PARQUET',
  overwrite=true,
  compression='SNAPPY'
) AS
SELECT
  exchange,
  symbol,
  side,
  price,
  amount,
  checksum,
  seq_id,
  is_snapshot,
  event_ts,
  receipt_ts,
  ingest_ts
FROM
  `cryptofeed-480903.cryptofeed.l2_book`
WHERE
  DATE(event_ts) = DATE('@run_date');
