# HelpWise Incident Report and Operations Runbook

Last updated: 2026-11-09 (Asia/Singapore)

## WS-F incident report

### Incident summary

HelpWise was unreachable because the LibreChat API container repeatedly crashed during startup. The reverse proxy and EC2 network path were available, but there was no healthy application process behind them.

### Root cause

The `CREDS_KEY` and `CREDS_IV` values supplied to LibreChat were in an invalid format. LibreChat uses these values for credential encryption and refused to start when they did not meet its requirements.

### Resolution

1. Inspected container status and startup logs.
2. Identified the credential-encryption validation failure.
3. Corrected the values in AWS Systems Manager Parameter Store as SecureString parameters.
4. Loaded the corrected values on the server without displaying them.
5. Recreated the API container and verified HTTP 200 from `/api/config`.
6. Added HTTPS through Caddy and verified the public application endpoint.

### Prevention

- Keep secrets in Parameter Store SecureString values, never in source control.
- Validate required secret formats during bootstrap before starting containers.
- Alert when the application health check fails or stops reporting.
- Retain container logs for diagnosis.
- Maintain nightly database backups and test restoration.

## Operational targets

- Backup RPO: approximately 24 hours, based on the nightly schedule.
- Measured restore RTO: 58 seconds in the isolated restore test.
- Health-check interval: 5 minutes.
- Log retention: 14 days.
- Backup retention: 7 days for current and noncurrent object versions.

## Runbook: application unavailable

1. Open the `HelpWise-Operations` CloudWatch dashboard.
2. Check `ApplicationHealthy`, synthetic errors, response time, CPU, memory, disk, and EC2 status.
3. Check the eight HelpWise CloudWatch alarms and their recent history.
4. On the server, inspect container status with `docker ps`.
5. Inspect recent logs for the API, MongoDB, Caddy, and the health-check service.
6. Verify the local API endpoint before checking the public HTTPS endpoint.
7. If a configuration or secret error appears, correct it in the authoritative AWS service; do not paste secret values into tickets, screenshots, or source control.
8. Restart only the affected service and verify HTTP 200 plus normal CloudWatch metrics.
9. Record the fault, timestamps, root cause, corrective action, and prevention measure.

## Runbook: backup failure

1. Check `systemctl status helpwise-backup.timer` and `systemctl status helpwise-backup.service`.
2. Review `/var/log/helpwise-backup.log`.
3. Confirm the EC2 role still contains `HelpWise-BackupBucketAccess`.
4. Confirm the S3 bucket exists, remains private, and has versioning and lifecycle retention enabled.
5. Run the backup service once manually.
6. Verify a new non-empty object appears under `mongodb/YYYY/MM/DD/`.
7. If upload fails, check role permissions, instance time, network access, and available disk space.

## Runbook: restore MongoDB

1. Select the newest known-good S3 archive.
2. Download it to a temporary root-owned file.
3. Start a separate temporary MongoDB container using the same image version as production.
4. Restore using `mongorestore --archive --gzip`.
5. Verify database and collection counts and inspect application-critical collections.
6. Record start/end timestamps and calculate RTO.
7. Remove the temporary container and archive.
8. Do not restore over production unless a declared recovery event has been approved and a fresh backup exists.

## Verified evidence

- Two successful backup objects created at 2026-11-09 02:29 UTC.
- Restore source: `mongodb/2026/11/09/helpwise-mongodb-20261109T022928Z.archive.gz`.
- Restore result: 61 collections and 1 user; RTO 58 seconds.
- Production remained healthy after the test and `/api/config` returned HTTP 200.

