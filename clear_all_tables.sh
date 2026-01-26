#!/bin/bash
set -e

PROJECT="cryptofeed-480903"
DATASET="cryptofeed"

# List of tables to clear
TABLES=(
    "okx_l2_book"
    "okx_ticker"
    "okx_trades"
    "okx_factors"
    "binance_l2_book"
    "binance_ticker"
    "binance_trades"
    "binance_factors"
)

echo "WARNING: This will DELETE ALL DATA from the following tables in $PROJECT:$DATASET:"
for t in "${TABLES[@]}"; do echo " - $t"; done
echo ""
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

for table in "${TABLES[@]}"; do
    echo "Truncating $table..."
    bq query --use_legacy_sql=false "TRUNCATE TABLE \`$PROJECT.$DATASET.$table\`"
done

echo "All tables cleared successfully."
