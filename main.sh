#!/usr/bin/env bash
set -e
while true; do
  date
  for ns in $(kubectl get namespace -o jsonpath="{ range .items[?(.metadata.annotations['rbac-sync\.nais\.io/group-name'])] }{.metadata.name } { end }"); do
    ips=$(kubectl get po -n istio-system -l app=prometheus -o json | jq -r -c '[.items[].status.podIP]')
    f=$(mktemp)
    echo $ns
cat > "$f" <<EOF 
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: prometheus-policy
  namespace: $ns
spec:
  rules:
  - from:
    - source:
        ipBlocks: $ips
    to:
    - operation:
        ports:
        - "15090"
        - "8080"
        - "9090"
  selector: {}
EOF
    kubectl apply -f "$f"
  done
  sleep 60
done