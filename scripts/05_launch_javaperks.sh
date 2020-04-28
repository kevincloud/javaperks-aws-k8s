#!/bin/bash

# Deploy auth-api
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/auth-api.yaml

# Deploy product-api
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/product-api.yaml

# Deploy customer-api
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/customer-api.yaml

# Deploy cart-api
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/cart-api.yaml

# Deploy cart-api
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/order-api.yaml

# Deploy store-api
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/online-store.yaml

# Deploy ldap
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/openldap.yaml

# Create ldap LB
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/ldap-front-end.yaml

# Create front-end LB
kubectl apply -f /root/javaperks-aws-k8s/scripts/javaperks/front-end.yaml
