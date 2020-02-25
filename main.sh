#!/usr/bin/env bash
set -e
while true; do
  ips=$(kubectl get po -n istio-system -l app=prometheus -o json | jq -r -c '[.items[].status.podIP]')
  f=$(mktemp)
cat > "$f" <<EOF 
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: prometheus-policy
  namespace: istio-system
spec:
  rules:
  - from:
    - source:
        ipBlocks: $ips
    to:
    - operation:
        ports:
        - "15090"
        - "9090"
        - "8080"
  selector: {}
EOF
kubectl apply -f "$f"
sleep 60
done
