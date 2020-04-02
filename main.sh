#!/bin/bash

readonly sleep_time=60

while true; do
  date
  ips=$(kubectl get po -n istio-system -l app=prometheus -o json | jq -r -c '[.items[].status.podIP]')
  for ns in $(kubectl get namespace -o jsonpath="{ range .items[?(.metadata.annotations['rbac-sync\.nais\.io/group-name'])] }{.metadata.name } { end }"); do
    declare -a PORTS=()
    for json in $(kubectl get deploy -n "$ns" -o json | jq -r -c '.items[].spec.template.metadata.annotations'); do
      scraping="$(echo "$json" | jq -r -c '."prometheus.io/scrape" == "true"')"
      if $scraping; then
        if [[ ! " ${PORTS[*]} " =~ $(echo "$json" | jq -r '."prometheus.io/port"') ]]; then
          PORTS+=("$(echo "$json" | jq -r '."prometheus.io/port"')")
        fi
      fi

    done
    if [ ${#PORTS[@]} -eq 0 ]; then
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
    for port in "${PORTS[@]}"; do
      echo "$port" | awk '{ printf("        - \"%s\"\n", $1)}' >> "$f"
    done
    echo "  selector: {}" >> "$f"
    echo "Found deployments with prometheus scraping true in namespace $ns."
		cat "$f"
    kubectl apply -f "$f"
  done

  echo "Sleeping for $sleep_time secs."
  sleep $sleep_time
done

