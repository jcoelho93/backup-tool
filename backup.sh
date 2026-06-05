#!/bin/bash
set -eo pipefail

: "${APP_NAME:?APP_NAME is required}"
: "${DATABASE_URL:?DATABASE_URL is required}"
: "${S3_BUCKET:?S3_BUCKET is required}"
: "${S3_ENDPOINT:?S3_ENDPOINT is required}"
: "${S3_ACCESS_KEY_ID:?S3_ACCESS_KEY_ID is required}"
: "${S3_SECRET_ACCESS_KEY:?S3_SECRET_ACCESS_KEY is required}"

TIMESTAMP=$(date -u +%Y-%m-%d_%H%M%S)
YEAR=$(date -u +%Y)
MONTH=$(date -u +%m)
FILENAME="${APP_NAME}-${TIMESTAMP}.sql.gz"
S3_KEY="backups/${YEAR}/${MONTH}/${FILENAME}"
TMP_FILE="/tmp/${FILENAME}"

echo "Starting backup: ${FILENAME}"

pg_dump \
  --data-only \
  --no-privileges \
  "${DATABASE_URL}" \
  | gzip > "${TMP_FILE}"

echo "Uploading to s3://${S3_BUCKET}/${S3_KEY}"

AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}" \
AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}" \
  aws s3 cp \
    "${TMP_FILE}" \
    "s3://${S3_BUCKET}/${S3_KEY}" \
    --endpoint-url "${S3_ENDPOINT}"

rm -f "${TMP_FILE}"
echo "Backup complete: s3://${S3_BUCKET}/${S3_KEY}"
