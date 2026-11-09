#!/usr/bin/env bash
set -Eeuo pipefail

BUCKET="sam10-helpwise-backups-511053876704"
REGION="ap-southeast-2"
TEST_CONTAINER="helpwise-mongodb-restore-test"
TMP_FILE="$(mktemp /var/tmp/helpwise-restore-test-XXXXXX.archive.gz)"
START_EPOCH="$(date +%s)"

cleanup() {
  docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
  rm -f -- "$TMP_FILE"
}
trap cleanup EXIT

LATEST_KEY="$(aws s3api list-objects-v2 --bucket "$BUCKET" --prefix mongodb/ --region "$REGION" --query 'sort_by(Contents,&LastModified)[-1].Key' --output text)"
test -n "$LATEST_KEY"
test "$LATEST_KEY" != "None"
aws s3 cp "s3://${BUCKET}/${LATEST_KEY}" "$TMP_FILE" --region "$REGION" --only-show-errors
test -s "$TMP_FILE"

MONGO_IMAGE="$(docker inspect --format '{{.Config.Image}}' chat-mongodb)"
docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$TEST_CONTAINER" "$MONGO_IMAGE" --bind_ip_all >/dev/null

for _ in $(seq 1 30); do
  if docker exec "$TEST_CONTAINER" mongosh --quiet --eval 'db.adminCommand({ping:1}).ok' 2>/dev/null | grep -qx 1; then
    break
  fi
  sleep 1
done
docker exec "$TEST_CONTAINER" mongosh --quiet --eval 'db.adminCommand({ping:1}).ok' | grep -qx 1
docker cp "$TMP_FILE" "$TEST_CONTAINER:/tmp/backup.archive.gz" >/dev/null
docker exec "$TEST_CONTAINER" mongorestore --archive=/tmp/backup.archive.gz --gzip >/tmp/helpwise-restore-output.log 2>&1

COLLECTIONS="$(docker exec "$TEST_CONTAINER" mongosh --quiet --eval 'db.getSiblingDB("LibreChat").getCollectionNames().length')"
USERS="$(docker exec "$TEST_CONTAINER" mongosh --quiet --eval 'db.getSiblingDB("LibreChat").users.countDocuments({})')"
END_EPOCH="$(date +%s)"
RTO_SECONDS="$((END_EPOCH - START_EPOCH))"

echo "RESTORE_TEST_SUCCESS"
echo "source_key=${LATEST_KEY}"
echo "collections=${COLLECTIONS}"
echo "users=${USERS}"
echo "rto_seconds=${RTO_SECONDS}"
