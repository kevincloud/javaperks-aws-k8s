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

# Create intentions
kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"*\", \"DestinationName\": \"*\", \"SourceType\": \"consul\", \"Action\": \"deny\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"online-store\", \"DestinationName\": \"auth-api\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"online-store\", \"DestinationName\": \"cart-api\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"online-store\", \"DestinationName\": \"customer-api\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"online-store\", \"DestinationName\": \"openldap-api\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"online-store\", \"DestinationName\": \"order-api\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"online-store\", \"DestinationName\": \"product-api\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"customer-api\", \"DestinationName\": \"vault\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"online-store\", \"DestinationName\": \"vault\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

kubectl exec hc-consul-consul-server-0 -- curl \
    --request POST \
    --data "{ \"SourceName\": \"auth-api\", \"DestinationName\": \"vault\", \"SourceType\": \"consul\", \"Action\": \"allow\" }" \
    http://127.0.0.1:8500/v1/connect/intentions

# Terminating gateways

# Ingress gateways

kubectl exec hc-consul-consul-server-0 -- curl \
    --request PUT \
    --data "{ \"Datacenter\": \"$AWS_REGION\", \"Node\": \"$CONSUL_NODE_ID\", \"Address\":\"$MYSQL_HOST\", \"Service\": { \"ID\": \"customer-db\", \"Service\": \"customer-db\", \"Address\": \"$MYSQL_HOST\", \"Port\": 3306 } }" \
    http://127.0.0.1:8500/v1/catalog/register

sudo bash -c "cat >/root/i-gtw-frontend.hcl" <<EOT
Kind = "ingress-gateway"
Name = "front-end-service"

TLS {
  Enabled = true
}

Listeners = [
  {
    Port = 80
    Protocol = "http"
    Services = [
      {
        Name = "front-end"
      }
    ]
  }
]
EOT

sudo bash -c cat >/root/t-gtw-mysql.hcl <<EOT
Kind = "terminating-gateway"
Name = "customer-db-service"
Services = [
    {
        Name = "customer-db"
    }
]
EOT
