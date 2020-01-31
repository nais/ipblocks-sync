# ipBlocks-sync
This container reads IP addresses of Prometheus pods in istio-system in order to create authorizationPolicies allowing prometheus pods to read all pods in all namespaces on port 15090.
If making changes run 
- `update image tag in Makefile`
- `make build`
- `make push`
- Update image version in https://github.com/navikt/nais-yaml
