#!/usr/bin/env bash
set -u

region="ap-southeast-2"
namespace="HelpWise/Application"
metric="ApplicationHealthy"
timestamp=$(date --iso-8601=seconds)
response_file=$(mktemp)
trap 'rm -f "$response_file"' EXIT

read -r http_code response_seconds < <(
  curl --silent --show-error --max-time 15 \
    --output "$response_file" \
    --write-out '%{http_code} %{time_total}' \
    http://127.0.0.1:3080/api/config || printf '000 15'
)
response_ms=$(awk -v seconds="$response_seconds" 'BEGIN { printf "%.0f", seconds * 1000 }')

if [[ "$http_code" == "200" ]] && grep -q 'HelpWise' "$response_file"; then
  value=1
  error_count=0
  status="healthy"
else
  value=0
  error_count=1
  status="unhealthy"
fi

aws cloudwatch put-metric-data \
  --region "$region" \
  --namespace "$namespace" \
  --metric-data \
    "MetricName=$metric,Value=$value,Unit=Count" \
    "MetricName=SyntheticRequestCount,Value=1,Unit=Count" \
    "MetricName=SyntheticErrorCount,Value=$error_count,Unit=Count" \
    "MetricName=SyntheticResponseTimeMs,Value=$response_ms,Unit=Milliseconds"

logger -t helpwise-health "timestamp=$timestamp status=$status http_code=$http_code response_ms=$response_ms error_count=$error_count"
printf '%s status=%s http_code=%s response_ms=%s error_count=%s\n' \
  "$timestamp" "$status" "$http_code" "$response_ms" "$error_count"
