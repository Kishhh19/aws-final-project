#!/usr/bin/env bash
set -Eeuo pipefail

BUCKET="sam10-helpwise-backups-511053876704"
REGION="ap-southeast-2"
CONTAINER="chat-mongodb"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
DAY_PATH="$(date -u +%Y/%m/%d)"
TMP_FILE="$(mktemp /var/tmp/helpwise-mongodb-${STAMP}-XXXXXX.archive.gz)"
S3_URI="s3://${BUCKET}/mongodb/${DAY_PATH}/helpwise-mongodb-${STAMP}.archive.gz"

cleanup() {
  rm -f -- "$TMP_FILE"
}
trap cleanup EXIT

echo "$(date -u +%FT%TZ) backup-start destination=${S3_URI}"
docker exec "$CONTAINER" mongodump --archive --gzip > "$TMP_FILE"
test -s "$TMP_FILE"
aws s3 cp "$TMP_FILE" "$S3_URI" --region "$REGION" --sse AES256 --only-show-errors
aws s3api head-object --bucket "$BUCKET" --key "${S3_URI#s3://${BUCKET}/}" --region "$REGION" >/dev/null
echo "$(date -u +%FT%TZ) backup-success bytes=$(stat -c %s "$TMP_FILE") destination=${S3_URI}"
