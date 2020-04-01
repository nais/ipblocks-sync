#!/usr/bin/env bash
set -e
while true; do
  date
  for ns in $(kubectl get namespace -o jsonpath="{ range .items[?(.metadata.annotations['rbac-sync\.nais\.io/group-name'])] }{.metadata.name } { end }"); do
    ips=$(kubectl get po -n istio-system -l app=prometheus -o json | jq -r -c '[.items[].status.podIP]')
    f=$(mktemp)
    ports=$(kubectl get app -n $ns -o json | jq -r -c '.items[].spec.port' | grep -v null | sort -u)
    echo "----- $ns -----"

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
EOF
    for port in $ports; do
      echo $port | awk '{ printf("        - \"%s\"\n", $1)}' >> $f
    done
    echo "  selector: {}" >> $f
    
    if [ ${#ports} -le 2 ]; then
      continue
    fi
    kubectl apply -f "$f"
  done
  sleep 60
done
