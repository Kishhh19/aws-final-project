# HelpWise — IT Helpdesk Assistant for Cobalt Dynamics

**SAM10 Systems Administration and Maintenance — Final Project**

A reskinned [LibreChat](https://github.com/danny-avila/LibreChat) deployment, operated as a production system on AWS: monitored, backed up, secured, and automated, with one deliberately diagnosed and resolved fault.

- **Live app:** <https://16-179-35-197.sslip.io>
- **Project website:** <https://project.16-179-35-197.sslip.io>
- **Region:** `ap-southeast-2` (Sydney)

## Repository layout

```
automation/   Scripts and unit/timer files for monitoring, backups, HTTPS, and the encrypted-volume migration
website/      Static source for the project website (WS-G)
docs/         Status reports, incident report & runbook (WS-F), continuation notes, video script
```

## Automations (WS-E)

| Automation | Schedule | What it does |
|---|---|---|
| Health-check / metrics publisher | every 5 minutes (systemd timer) | Publishes `ApplicationHealthy`, `SyntheticRequestCount`, `SyntheticErrorCount`, `SyntheticResponseTimeMs` to CloudWatch |
| Nightly MongoDB backup | 02:30 UTC daily (systemd timer, persistent, randomized delay) | Dumps MongoDB, compresses, uploads to the private encrypted S3 backup bucket |

Deploy either one by copying its `.service`/`.timer` pair from `automation/` to `/etc/systemd/system/` on the instance, then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now helpwise-health-check.timer
sudo systemctl enable --now helpwise-backup.timer
```

## Fault diagnosed and fixed (WS-F)

The LibreChat container was crash-looping on an invalid `CREDS_KEY`/`CREDS_IV` secret format (48-character alphanumeric instead of 64/32-character hex). Full root cause, fix, prevention, and runbook: [`docs/INCIDENT_REPORT_AND_RUNBOOK.md`](docs/INCIDENT_REPORT_AND_RUNBOOK.md).

## Security

- No secrets in code or in this repository — all credentials live in AWS Systems Manager Parameter Store (SecureString)
- MFA enabled for both the `mark-santos` IAM user and the account root user
- IMDSv2 required on the EC2 instance
- Database ports are not publicly exposed; SSH restricted to a single `/32`
- CloudTrail logging management events, multi-region, with log-file validation
- Application/database data on an encrypted EBS volume (`aws/ebs`)

## Weekly log

- **Week of 2026-11-03:** Initial AWS deployment of the LibreChat/HelpWise stack; EC2, security group, IAM role set up.
- **Week of 2026-11-09:**
  - Diagnosed and fixed an EBS disk-exhaustion issue blocking Docker image pulls (volume resize 8→30 GiB, partition/filesystem grown).
  - Diagnosed and fixed the LibreChat crash-loop caused by an invalid `CREDS_KEY`/`CREDS_IV` format — this is the project's official WS-F fault.
  - Added HTTPS via Caddy with a trusted Let's Encrypt certificate.
  - Stood up monitoring: CloudWatch agent, two log groups (14-day retention), custom metrics, dashboard `HelpWise-Operations`, 8 alarms, SNS email subscription, controlled alarm test.
  - Stood up backups: private/versioned/encrypted S3 bucket, 7-day lifecycle, least-privilege EC2 role policy, nightly systemd timer, two unattended runs verified, isolated restore test passed (61 collections, 1 user, 58s RTO).
  - Enabled multi-region CloudTrail.
  - Migrated Docker application/database data to an encrypted EBS volume.
  - Enabled MFA on both the IAM user and the account root user.
  - Attempted GuardDuty — blocked by an AWS account verification/free-plan restriction (evidence retained; S-tier stretch item).
  - Rotated the previously exposed Gemini API key in Parameter Store and propagated it into the running LibreChat container (recreated via Docker Compose), verified the app still serves HTTPS correctly afterward.
  - Drafted the presentation video script.
  - Pushed all automation/configuration source and documentation to this repository.

## Contribution log

- Mark Santos — sole contributor (solo submission).
