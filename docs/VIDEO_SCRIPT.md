# HelpWise — Presentation Video Script / Storyboard

Target length: **5–8 minutes** (D2 requirement). Follows the website's structure per the rubric, and is meant to be presented live with a screen share — not read word-for-word, but hit every beat below so no marks are left on the table.

Record with OBS Studio (free) or Windows' built-in Xbox Game Bar (Win+G) screen recorder. Upload unlisted to YouTube, then embed the link on the project website.

**Before recording:** close any tab/terminal showing a real secret (Parameter Store values, the Gemini key, AWS account ID if you'd rather blur it, SSH key paths). Blur your face is not required, but blur anything in Section 1.2's "no personal data" list if it's on screen.

---

## 0:00–0:30 — Cold open / who & what

- Say your name (and partner's, if any).
- One sentence: *"This is HelpWise, an IT helpdesk assistant for a fictional company called Cobalt Dynamics, built on LibreChat and deployed on AWS. I'm going to show you the system running, how it's operated, and a real fault I found and fixed."*
- Show the live site loading: `https://16-179-35-197.sslip.io` — point out the padlock/trusted HTTPS.

## 0:30–1:30 — Executive summary (website section 1)

- What the system does in plain English: an AI chat assistant employees can ask IT questions.
- What was wrong with how it was *originally* run (disk filling up, a crash-looping container from a bad secret format, no monitoring/backups/encryption at the start).
- What you changed, one sentence each: fixed the crash, added HTTPS, monitoring, backups, encryption, hardened security, automated two things.
- What improved (point at the before/after table on the site).

## 1:30–2:30 — AWS infrastructure design (section 2)

- Show your architecture diagram on screen.
- Walk the request path out loud: *user → HTTPS (Caddy, port 443) → LibreChat container → MongoDB / Meilisearch / pgvector (RAG) → Gemini model API → response back.*
- Name each AWS piece you actually used: EC2 (t3.micro), two EBS volumes (root unencrypted, encrypted data volume for Docker), S3 (backups), CloudWatch, SNS, CloudTrail, Systems Manager (Parameter Store + Run Command/Session Manager).

## 2:30–3:15 — The system & system card (section 3)

- Base system = LibreChat (open source), reskinned as "HelpWise" for Cobalt Dynamics.
- Model = Gemini (name the tier/plan you're on).
- What it can't do / who shouldn't use it — be honest here, this is explicitly worth marks (e.g. no access to real company systems, answers can be wrong, not for anything safety-critical, no PII should be entered).

## 3:15–3:45 — Baseline (section 4)

- One sentence + a screenshot: what the environment looked like before you touched it (single EC2 instance, plain HTTP, no monitoring, default/weak secrets, 8 GiB disk).

## 3:45–5:00 — Monitoring, backup/restore, and security — LIVE DEMO (section 6)

This is the section markers most want to see live, not described:
- Switch to the CloudWatch dashboard `HelpWise-Operations` — point at the widgets (CPU, memory, disk, synthetic health check).
- Show the 8 alarms, and the real alert email you received during the controlled test.
- Show the S3 backup bucket: versioned, encrypted, private, lifecycle rule, and the two+ backup objects with real timestamps.
- Show (or narrate over a screenshot of) the isolated restore test result: 61 collections, 1 user, 58-second RTO.
- Show the before/after security table: HTTP→HTTPS, no monitoring→CloudWatch+SNS, unencrypted data→encrypted EBS volume, open ports→SSH restricted to one /32, CloudTrail on, MFA on both mark-santos and root.

## 5:00–6:15 — Automation & the incident (section 7)

- Automation 1: the 5-minute health-check/metrics publisher — show the systemd timer `active (waiting)` and two+ real run timestamps.
- Automation 2: the nightly backup timer — same evidence.
- The fault (WS-F): *"LibreChat kept crash-looping. The error said CREDS_KEY must be exactly 64 hex characters. I found the stored secret was 48 characters of mixed-case letters and digits — it had been generated with the wrong kind of random string, not a hex string."*
- Root cause: wrong generator used when the secret was first created → invalid format → LibreChat's startup validation refused to boot (by design, to prevent weak encryption).
- Fix: regenerated correct values with `openssl rand -hex 32` / `-hex 16`, updated them in Parameter Store, pulled them into the instance's `.env`, recreated the container.
- Prevention: added the CloudWatch alarm on application health so this class of failure pages immediately next time.
- Timings: time started, time noticed, time fixed (pull these from your incident report).

## 6:15–7:00 — Results (section 8)

- Before/after side by side: uptime/health, backup existence, HTTPS, cost. Use the same screenshots as the site.
- State the monthly cost explicitly (before and after), since the rubric calls this out by name.

## 7:00–7:30 — What's next (section 9)

- 3–5 ideas in priority order, e.g.: enable GuardDuty once the AWS account restriction clears, encrypt the OS root volume too, add CI/CD auto-deploy from the repo, add a second AZ/instance for redundancy, rotate the Gemini key on a schedule.

## 7:30–8:00 — Close

- One line thanking the viewer, restate the live URL, done.

---

## Checklist before you hit record

- [ ] Browser zoomed so text is readable on a recording (Ctrl/Cmd + "+" a couple notches)
- [ ] AWS account ID and any key fragments blurred or cropped out of shot
- [ ] Have the CloudWatch dashboard, S3 bucket, alarm history, and systemd timer status pre-opened in tabs so you're not hunting for them live
- [ ] Know your two timer run timestamps and the restore RTO number by heart or on a sticky note just off-camera
- [ ] Practice once at normal talking speed with a stopwatch — this script runs close to 8:00 if read at a natural pace, so trim if you're running long
