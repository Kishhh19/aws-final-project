# HelpWise Final Project Status

Last updated: 2026-11-09 (Asia/Singapore)

## Working production system

- HTTPS: <https://16-179-35-197.sslip.io>
- Final project website: <https://project.16-179-35-197.sslip.io>
- EC2: `i-00ecc810f659fc312`, Sydney (`ap-southeast-2`)
- Instance: `t3.micro`, IMDSv2 required
- Public web ports: 80 and 443
- SSH: port 22 restricted to one `/32` address
- Database ports: not publicly exposed

## Requirements completed

### Monitoring and alerting

- CloudWatch dashboard: `HelpWise-Operations`
- System, application, request, error, latency, CPU, disk, memory, swap, network, and EC2 status visibility
- Eight CloudWatch alarms
- SNS email subscription confirmed
- Controlled synthetic-error test entered ALARM
- System and container logs retained for 14 days

### Backup and recovery

- Private S3 bucket with Block Public Access
- Versioning and SSE-S3 encryption enabled
- Seven-day current/noncurrent retention lifecycle
- Incomplete multipart uploads removed after one day
- Least-privilege EC2 role access to only the backup bucket
- Nightly persistent systemd timer
- Two successful unattended runs
- Isolated restore test passed
- RPO approximately 24 hours; measured RTO 58 seconds

### Security

- No root access keys
- MFA is enabled for the named IAM user `mark-santos` (verified from the IAM dashboard evidence supplied by the user).
- Secrets stored outside source code
- IMDSv2 required
- Database ports are not public
- HTTPS with a trusted certificate
- Application and database Docker data migrated to encrypted 20 GiB gp3 EBS volume `vol-036b0510ab52373d2` using AWS-managed key `aws/ebs`.
- Multi-region CloudTrail management-event logging enabled
- CloudTrail log-file validation enabled
- GuardDuty attempted but blocked by the AWS account's incomplete/free-plan restrictions

### Automation

- Five-minute health-check and custom-metric publisher
- Nightly MongoDB backup to S3
- Both automations have successful unattended execution evidence

### Fault analysis

- Official fault: invalid LibreChat `CREDS_KEY`/`CREDS_IV` format
- Root cause, resolution, prevention, and operations runbook documented

## Remaining blockers or user-controlled steps

1. MFA is enabled for IAM user `mark-santos`. Root-account MFA is a separate control and previously showed `0`; enable it separately if the rubric explicitly requires root MFA.
2. GuardDuty cannot be enabled until AWS account verification/plan restrictions are resolved.
3. Rotate the previously exposed Gemini API key.
4. Record and embed the presentation video, then produce the final repository ZIP evidence package.

## Evidence checklist

- Application HTTPS page
- CloudWatch dashboard
- Alarm list and test email
- Log groups and 14-day retention
- S3 bucket privacy, encryption, versioning, and lifecycle rule
- Two backup objects
- Restore-test output
- IAM role policies
- EC2 security-group rules
- CloudTrail logging status
- Root MFA status after enrollment
- GuardDuty page or AWS account restriction evidence
- Incident report and runbook

