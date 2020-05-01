#!/bin/bash

# # Add Ambassador helm repo
# helm repo add datawire https://www.getambassador.io

# # Create namespace
# kubectl create namespace ambassador

# # Install Ambassador
# helm install hc-ambassador datawire/ambassador -n ambassador

# # Add RBAC
# kubectl apply -f "https://www.getambassador.io/yaml/ambassador/ambassador-rbac.yaml"

# # Add Consul Resolver
# bash -c "cat >/root/consul-resolver.yaml" <<EOT
# apiVersion: getambassador.io/v2
# kind: ConsulResolver
# metadata:
#   name: consul-$AWS_REGION
# spec:
#   address: consul:8500
#   datacenter: $AWS_REGION
# EOT
