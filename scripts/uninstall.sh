#!/bin/bash

# Delete Java Perks
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/ldap-front-end.yaml
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/front-end.yaml
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/auth-api.yaml
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/product-api.yaml
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/customer-api.yaml
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/cart-api.yaml
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/order-api.yaml
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/online-store.yaml
kubectl delete -f /root/javaperks-aws-k8s/scripts/javaperks/openldap.yaml

# Delete Kubernetes Dashboard
kubectl delete -f "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc7/aio/deploy/recommended.yaml"

# Delete Vault
helm delete hc-vault

# Delete Consul
helm delete hc-consul
kubectl delete service consul

# Delete persistent storage
kubectl delete pvc data-default-hc-consul-consul-server-0
kubectl delete pvc data-default-hc-consul-consul-server-1
kubectl delete pvc data-default-hc-consul-consul-server-2
kubectl delete pvc data-hc-vault-0

# Delete maps
kubectl delete configmap env-values
kubectl delete secret env-secret-values
