#!/usr/bin/env bash
set -e

sleep_time=60

while true; do
  date
  ips=$(kubectl get po -n istio-system -l app=prometheus -o json | jq -r -c '[.items[].status.podIP]')
  for ns in $(kubectl get namespace -o jsonpath="{ range .items[?(.metadata.annotations['rbac-sync\.nais\.io/group-name'])] }{.metadata.name } { end }"); do
    echo "----- $ns -----"
    ports=$(kubectl get app -n "$ns" -o json | jq -r -c '.items[].spec.port' | grep -v null | sort -u)
    if [ ${#ports} -le 2 ]; then
      echo "No applications configured in namespace [$ns]"
      continue
    fi
    f=$(mktemp)
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
EOF
    for port in $ports; do
      echo "$port" | awk '{ printf("        - \"%s\"\n", $1)}' >> "$f"
    done
    echo "  selector: {}" >> "$f"
    kubectl apply -f "$f"
  done

  echo "Sleeping for $sleep_time secs."
  sleep $sleep_time
done