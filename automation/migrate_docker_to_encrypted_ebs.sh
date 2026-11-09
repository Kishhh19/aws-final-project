#!/usr/bin/env bash
set -Eeuo pipefail

DEVICE="/dev/nvme1n1"
MOUNT="/mnt/helpwise-docker"
DOCKER_DIR="/var/lib/docker"
ROLLBACK_DIR="/var/lib/docker.unencrypted-rollback"
FSTAB_MARKER="# HelpWise encrypted Docker data"

test -b "$DEVICE"
test "$(lsblk -ndo SERIAL "$DEVICE")" = "vol036b0510ab52373d2"
test -d "$DOCKER_DIR"
test ! -e "$ROLLBACK_DIR"
command -v rsync >/dev/null

echo "$(date -u +%FT%TZ) migration-start"
systemctl start helpwise-backup.service

if ! blkid "$DEVICE" >/dev/null 2>&1; then
  mkfs.ext4 -F -L helpwise-docker "$DEVICE"
fi

mkdir -p "$MOUNT"
mountpoint -q "$MOUNT" || mount "$DEVICE" "$MOUNT"
rsync -aHAXx --numeric-ids "$DOCKER_DIR/" "$MOUNT/"

systemctl stop helpwise-health-check.timer || true
systemctl stop docker
rsync -aHAXx --numeric-ids --delete "$DOCKER_DIR/" "$MOUNT/"

mv "$DOCKER_DIR" "$ROLLBACK_DIR"
mkdir -p "$DOCKER_DIR"
UUID="$(blkid -s UUID -o value "$DEVICE")"
printf '%s\nUUID=%s /var/lib/docker ext4 defaults,nofail 0 2\n' "$FSTAB_MARKER" "$UUID" >> /etc/fstab
umount "$MOUNT"
mount "$DOCKER_DIR"

rollback() {
  echo "$(date -u +%FT%TZ) migration-rollback" >&2
  systemctl stop docker || true
  umount "$DOCKER_DIR" || true
  sed -i "/^# HelpWise encrypted Docker data$/,+1d" /etc/fstab
  rmdir "$DOCKER_DIR" || true
  mv "$ROLLBACK_DIR" "$DOCKER_DIR"
  systemctl start docker
  systemctl start helpwise-health-check.timer || true
}
trap rollback ERR

systemctl start docker
for _ in $(seq 1 60); do
  if curl -fsS --max-time 5 http://127.0.0.1:3080/api/config >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
curl -fsS --max-time 10 http://127.0.0.1:3080/api/config >/dev/null
docker ps --format '{{.Names}} {{.Status}}'

systemctl start helpwise-health-check.timer
trap - ERR
rm -rf -- /var/lib/docker.unencrypted-rollback

echo "$(date -u +%FT%TZ) migration-success"
findmnt /var/lib/docker
df -h /var/lib/docker
lsblk -o NAME,SERIAL,SIZE,FSTYPE,MOUNTPOINTS
