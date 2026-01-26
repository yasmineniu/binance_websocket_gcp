#!/bin/bash
set -e

# Configuration
BUCKET_NAME="cryptofeed-480903-data" # Default bucket name, change if needed
PROJECT_ID="cryptofeed-480903"

# Date handling (default to yesterday if not provided)
if [ -z "$1" ]; then
    RUN_DATE=$(date -v-1d +%Y-%m-%d)
else
    RUN_DATE="$1"
fi

echo "Starting Parquet export for date: $RUN_DATE to bucket: $BUCKET_NAME"

# Check if bucket exists, create if not
if ! gsutil ls -b gs://$BUCKET_NAME > /dev/null 2>&1; then
    echo "Bucket $BUCKET_NAME does not exist. Creating..."
    gsutil mb -p $PROJECT_ID -l US gs://$BUCKET_NAME
fi

# Prepare SQL query
# We use sed to replace placeholders in the SQL template
sed -e "s/@run_date/$RUN_DATE/g" \
    -e "s/@bucket_name/$BUCKET_NAME/g" \
    export_daily_parquet.sql > temp_export.sql

# Execute Query
echo "Running export query..."
bq query --use_legacy_sql=false --project_id=$PROJECT_ID < temp_export.sql

echo "Export complete. Verify data at: gs://$BUCKET_NAME/l2_book/dt=$RUN_DATE/"
# rm temp_export.sql
