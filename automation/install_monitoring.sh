#!/usr/bin/env bash
set -euo pipefail

deb=/tmp/amazon-cloudwatch-agent.deb
curl --fail --location --silent --show-error \
  https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
  --output "$deb"
dpkg -i "$deb"

install -m 0644 /tmp/cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
install -m 0755 /tmp/helpwise-health-check.sh /usr/local/bin/helpwise-health-check.sh
install -m 0644 /tmp/helpwise-health-check.service /etc/systemd/system/helpwise-health-check.service
install -m 0644 /tmp/helpwise-health-check.timer /etc/systemd/system/helpwise-health-check.timer

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

systemctl daemon-reload
systemctl enable --now helpwise-health-check.timer
systemctl start helpwise-health-check.service

echo MONITORING_READY
systemctl --no-pager --full status amazon-cloudwatch-agent | sed -n '1,12p'
systemctl --no-pager --full status helpwise-health-check.timer | sed -n '1,12p'
journalctl -u helpwise-health-check.service -n 10 --no-pager
