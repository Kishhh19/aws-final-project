#!/usr/bin/env bash
set -euo pipefail

region="ap-southeast-2"
instance_id="i-00ecc810f659fc312"
topic_arn=$(aws sns create-topic --region "$region" --name HelpWise-Alerts --query TopicArn --output text)

common=(--region "$region" --alarm-actions "$topic_arn" --ok-actions "$topic_arn")

aws cloudwatch put-metric-alarm "${common[@]}" \
  --alarm-name HelpWise-CPU-High \
  --alarm-description "CPU above 85 percent for 10 minutes" \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value="$instance_id" \
  --statistic Average --period 300 --evaluation-periods 2 --datapoints-to-alarm 2 \
  --threshold 85 --comparison-operator GreaterThanThreshold --treat-missing-data missing

aws cloudwatch put-metric-alarm "${common[@]}" \
  --alarm-name HelpWise-Memory-High \
  --alarm-description "Memory above 85 percent for 10 minutes" \
  --namespace HelpWise/EC2 --metric-name mem_used_percent \
  --dimensions Name=InstanceId,Value="$instance_id" \
  --statistic Average --period 300 --evaluation-periods 2 --datapoints-to-alarm 2 \
  --threshold 85 --comparison-operator GreaterThanThreshold --treat-missing-data missing

aws cloudwatch put-metric-alarm "${common[@]}" \
  --alarm-name HelpWise-Disk-High \
  --alarm-description "Root disk usage above 80 percent" \
  --namespace HelpWise/EC2 --metric-name disk_used_percent \
  --dimensions Name=InstanceId,Value="$instance_id" \
  --statistic Average --period 300 --evaluation-periods 1 --datapoints-to-alarm 1 \
  --threshold 80 --comparison-operator GreaterThanThreshold --treat-missing-data missing

aws cloudwatch put-metric-alarm "${common[@]}" \
  --alarm-name HelpWise-EC2-Status-Failed \
  --alarm-description "EC2 instance or system status check failed" \
  --namespace AWS/EC2 --metric-name StatusCheckFailed \
  --dimensions Name=InstanceId,Value="$instance_id" \
  --statistic Maximum --period 60 --evaluation-periods 2 --datapoints-to-alarm 2 \
  --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --treat-missing-data breaching

aws cloudwatch put-metric-alarm "${common[@]}" \
  --alarm-name HelpWise-Application-Unhealthy \
  --alarm-description "Scheduled HelpWise health check reports unhealthy or stops reporting" \
  --namespace HelpWise/Application --metric-name ApplicationHealthy \
  --statistic Minimum --period 300 --evaluation-periods 2 --datapoints-to-alarm 2 \
  --threshold 1 --comparison-operator LessThanThreshold --treat-missing-data breaching

aws cloudwatch put-metric-alarm "${common[@]}" \
  --alarm-name HelpWise-Synthetic-Errors \
  --alarm-description "Scheduled request returned an error" \
  --namespace HelpWise/Application --metric-name SyntheticErrorCount \
  --statistic Sum --period 300 --evaluation-periods 1 --datapoints-to-alarm 1 \
  --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --treat-missing-data breaching

aws cloudwatch put-metric-alarm "${common[@]}" \
  --alarm-name HelpWise-Response-Time-High \
  --alarm-description "Synthetic response time above three seconds for 10 minutes" \
  --namespace HelpWise/Application --metric-name SyntheticResponseTimeMs \
  --statistic Average --period 300 --evaluation-periods 2 --datapoints-to-alarm 2 \
  --threshold 3000 --comparison-operator GreaterThanThreshold --treat-missing-data breaching

aws cloudwatch put-metric-alarm "${common[@]}" \
  --alarm-name HelpWise-Request-Check-Missing \
  --alarm-description "No successful scheduled request count received" \
  --namespace HelpWise/Application --metric-name SyntheticRequestCount \
  --statistic Sum --period 300 --evaluation-periods 2 --datapoints-to-alarm 2 \
  --threshold 1 --comparison-operator LessThanThreshold --treat-missing-data breaching

echo "TOPIC_ARN=$topic_arn"
aws cloudwatch describe-alarms --region "$region" \
  --alarm-name-prefix HelpWise- \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Metric:MetricName}' \
  --output table
