#!/bin/sh

set -e

latest_verdict_pod_name=$(kubectl get pod -l role=reliability-verdict -n litmus -o json | jq -r '.items | sort_by(.metadata.creationTimestamp | fromdate) |  last(.[]).metadata.name')
#// TODO minor MKN: handle not found: latest_verdict_pod_name
argo logs @latest "${latest_verdict_pod_name}" --timestamps --no-color -n litmus
