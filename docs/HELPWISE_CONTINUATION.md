# HelpWise Project Continuation

Last updated: 2026-11-09 (Asia/Singapore)

## Current working application

- EC2 instance: `i-00ecc810f659fc312`
- Region: `ap-southeast-2`
- Public IP: `16.179.35.197`
- HTTPS URL: <https://16-179-35-197.sslip.io>
- Deployment path: `/opt/helpwise/librechat`
- Application containers are running, including LibreChat, MongoDB, Meilisearch, RAG API, PostgreSQL/pgvector, admin panel, and Caddy.

## Completed work

- Fixed invalid LibreChat `CREDS_KEY` and `CREDS_IV` values by reading the corrected SecureString parameters server-side.
- Published LibreChat on port 80 and verified HTTP 200.
- Added a persistent 2 GiB swap file to stabilize the t3.micro instance.
- Added Caddy on port 443 and obtained a trusted Let's Encrypt certificate for `16-179-35-197.sslip.io`.
- Verified the HTTPS home page and `/api/config` return HTTP 200 and identify the app as HelpWise.
- Installed and started the Amazon CloudWatch agent.
- Created CloudWatch log groups `/sam10/helpwise/system` and `/sam10/helpwise/containers` with 14-day retention.
- Added custom `HelpWise/EC2` metrics for memory, disk, swap, and network activity.
- Added a five-minute systemd health-check automation that publishes:
  - `ApplicationHealthy`
  - `SyntheticRequestCount`
  - `SyntheticErrorCount`
  - `SyntheticResponseTimeMs`
- Created and saved the CloudWatch dashboard `HelpWise-Operations` with system, application, CPU, and EC2 status widgets.
- Created eight CloudWatch alarms connected to the `HelpWise-Alerts` SNS topic.
- Confirmed the SNS email subscription for `marklaurencesantos558@gmail.com`.
- Published a controlled synthetic-error datapoint and verified CloudWatch showed one alarm in `ALARM` and seven alarms in `OK`.
- Created private, versioned, SSE-S3 encrypted bucket `sam10-helpwise-backups-511053876704` with Block Public Access enabled.
- Enabled lifecycle rule `Expire-backups-after-7-days` for the entire backup bucket:
  - Expire current versions after 7 days.
  - Permanently delete noncurrent versions after 7 days.
  - Abort incomplete multipart uploads after 1 day.
- Added inline role policy `HelpWise-BackupBucketAccess` to `sam10-helpwise-ec2-role`, scoped only to the dedicated backup bucket and its objects. It grants bucket listing/location plus object upload, download, and multipart-abort access; it does not grant bucket deletion or broad S3 access.
- Installed and enabled `helpwise-backup.timer`, scheduled nightly at 02:30 UTC with persistence and a small randomized delay.
- Ran the backup automation twice unattended and verified two encrypted S3 objects:
  - `mongodb/2026/11/09/helpwise-mongodb-20261109T022922Z.archive.gz` (11,560 bytes)
  - `mongodb/2026/11/09/helpwise-mongodb-20261109T022928Z.archive.gz` (11,572 bytes)
- Restored the newest archive into an isolated temporary MongoDB container without touching production:
  - Result: `RESTORE_TEST_SUCCESS`
  - Restored collections: 61
  - Restored users: 1
  - Measured RTO: 58 seconds
  - Backup schedule supports an RPO of approximately 24 hours.
- Verified after the restore test that all production containers remained running, the backup timer was active/enabled, and the local HelpWise API returned HTTP 200.
- Created multi-region CloudTrail `HelpWise-Audit-Trail` in Sydney. It is logging read/write management events to `aws-cloudtrail-logs-511053876704-91f690e0` with log-file validation and recursive logging enabled. This is the account's first management-event copy, shown by AWS as having no additional CloudTrail event charge; normal S3 storage charges can still apply.
- Verified the EC2 security group exposes only HTTP 80, HTTPS 443, and SSH 22 restricted to `120.29.76.131/32`. MongoDB and other database ports are not publicly exposed.
- Verified IMDSv2 is required and the root account has no access keys.

## Important blockers and decisions

- CloudFront and CloudShell cannot create resources because AWS says account verification is still in progress. Caddy is the working HTTPS solution.
- GuardDuty is also blocked by the incomplete/free-plan account setup page, so it cannot be enabled until AWS account verification/plan restrictions are resolved.
- MFA is enabled for IAM user `mark-santos`, verified by the user's IAM dashboard screenshot. This is separate from root-account MFA, which previously showed `MFA (0)` while signed in as root. If the rubric requires root MFA specifically, it still needs separate enrollment.
- The root OS volume remains unencrypted, but all Docker application/database data now resides on encrypted EBS volume `vol-036b0510ab52373d2` using AWS-managed key `aws/ebs`.
- Encrypted-data-volume migration preflight completed:
  - Availability Zone: `ap-southeast-2c`
  - Current Docker data: 6.3 GiB
  - Root volume: 29 GiB usable, 16 GiB used, 13 GiB free
  - Backup timer active and HelpWise API HTTP 200 before migration
  - Proposed approach: add a 20 GiB encrypted gp3 volume and move `/var/lib/docker` during a short Docker-only maintenance window, preserving the EC2 instance, public IP, and HTTPS hostname.
- Encrypted-data migration completed successfully at 2026-11-09 02:45 UTC:
  - `/var/lib/docker` is persistently mounted from `/dev/nvme1n1` by filesystem UUID.
  - All seven containers restarted and remained healthy.
  - MongoDB retained 1 user and Docker retained all 7 images/containers.
  - Backup and health-check timers are active.
  - Four S3 backup objects exist after the pre-migration backup.
  - Local and external HTTPS checks returned HTTP 200; TLS verification result was 0.
- The optional CloudFront WAF estimate was about US$14/month and was intentionally not enabled.
- The recommended WS-F diagnosed fault is the invalid `CREDS_KEY`/`CREDS_IV` format that caused the LibreChat crash loop.
- Never type or expose passwords, API keys, tokens, or SecureString values. The exposed Gemini key still needs to be rotated by the user.

## Current task in progress

- Created SNS topic `HelpWise-Alerts` in `ap-southeast-2`.
- Created eight CloudWatch alarms connected to the SNS topic:
  - `HelpWise-CPU-High`
  - `HelpWise-Memory-High`
  - `HelpWise-Disk-High`
  - `HelpWise-EC2-Status-Failed`
  - `HelpWise-Application-Unhealthy`
  - `HelpWise-Synthetic-Errors`
  - `HelpWise-Response-Time-High`
  - `HelpWise-Request-Check-Missing`
- The scoped `HelpWise-TemporaryMonitoringSetup` inline policy was removed after resource creation. The EC2 role is back to its three intended policies.
- The SNS email subscription is confirmed.
- The controlled alert test fired successfully in CloudWatch. The user should retain the received alarm email as WS-B evidence and confirm that the alarm later returns to `OK`.
- WS-C backup, retention, least-privilege bucket access, two-run automation evidence, and isolated restore testing are complete.

## Remaining assignment work

- Complete security hardening: MFA evidence, CloudTrail, encryption at rest, GuardDuty, least privilege, and database exposure checks.
- Complete the second unattended automation and collect two run timestamps for each automation.
- Write the WS-F root-cause report and Appendix D runbook.
- Push the IMDSv2 bootstrap fix and all automation/configuration code to the project repository.
- Rotate the exposed Gemini API key.
- Build the project website, infrastructure diagram, evidence sections, evaluation, test questions, and embedded presentation video.
- Update weekly logs and package the final repository ZIP.

## Local working files

Intermediate configuration and scripts are under:

`C:\Users\kramg\Documents\Codex\2026-11-09\use-x20\work`

Final-project documentation created:

- `outputs\FINAL_PROJECT_STATUS.md`
- `outputs\INCIDENT_REPORT_AND_RUNBOOK.md`
- `outputs\helpwise-final-site.zip`

Final project website source was created and registered as the private Sites project `HelpWise AWS Final Project` (`appgprj_6af1349878ac81918b25a025ae6c367c`). The local source and deployable ZIP are complete. Sites source synchronization timed out; do not create a second Site—reuse this project ID if retrying. As a working fallback, the website was published through the existing encrypted Caddy deployment at <https://project.16-179-35-197.sslip.io>. External checks returned HTTP 200 with TLS verification result 0, and the main HelpWise endpoint remained HTTP 200.

The original project handoff is:

`C:\Users\kramg\Downloads\HANDOFF.md`
