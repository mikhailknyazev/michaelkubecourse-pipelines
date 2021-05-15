#!/bin/sh

set -e

argo_hostname=$(kubectl get ingress argo-server -n litmus -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
wf_name=$(argo get @latest -n litmus --no-color -o json | jq -r '.metadata.name')
wf_url="http://${argo_hostname}/workflows/litmus/${wf_name}"

echo "${wf_url}"
exit 0
