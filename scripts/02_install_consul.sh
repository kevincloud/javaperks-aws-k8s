#!/bin/bash

# Install Consul
cd /root
git clone https://github.com/hashicorp/consul-k8s.git
sudo bash -c "cat >/root/helm-consul-values.yaml" <<EOT
# helm-consul-values.yaml
global:
  image: "hashicorp/${CONSUL_HELM}"
  imageK8S: "kschoche/consul-k8s-dev-vault"
  datacenter: $AWS_REGION
  # acls:
  #   manageSystemACLs: true

server:
  replicas: 3
  bootstrapExpect: 3
  # enterpriseLicense:
  #   secretName: env-secret-values
  #   secretKey: consul-license

client:
  enabled: true

ui:
  service:
    type: 'LoadBalancer'

syncCatalog:
  enabled: true
EOT

helm install -f helm-consul-values.yaml hc-consul ./consul-k8s/charts/consul

sleep 2

# Wait until all pods are healthy
while [[ ! -z $(kubectl get pods | grep hc-consul | sed -n '1d; /Running/ !p') ]]; do
    sleep 5
done

echo "Get Consul node id..."
export CONSUL_NODE_ID=$(kubectl exec hc-consul-consul-server-0 -- curl -s http://127.0.0.1:8500/v1/catalog/node/hc-consul-consul-server-0 | jq -r .Node.ID)

# register the database host with consul
echo "Registering customer-db with consul..."
# echo "{ \"Datacenter\": \"$AWS_REGION\", \"Node\": \"$CONSUL_NODE_ID\", \"Address\":\"$MYSQL_HOST\", \"Service\": { \"ID\": \"customer-db\", \"Service\": \"customer-db\", \"Address\": \"$MYSQL_HOST\", \"Port\": 3306 } }"
kubectl exec hc-consul-consul-server-0 -- curl \
    --request PUT \
    --data "{ \"Datacenter\": \"$AWS_REGION\", \"Node\": \"$CONSUL_NODE_ID\", \"Address\":\"$MYSQL_HOST\", \"Service\": { \"ID\": \"customer-db\", \"Service\": \"customer-db\", \"Address\": \"$MYSQL_HOST\", \"Port\": 3306 } }" \
    http://127.0.0.1:8500/v1/catalog/register

# Enable Consul DNS resolution
export COREDNS_IP=$(kubectl get svc hc-consul-consul-dns -o jsonpath='{.spec.clusterIP}')
kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' > /root/dns-settings.txt
sudo bash -c "cat >>/root/dns-settings.txt" <<EOT
consul {
  errors
  cache 30
  forward . $COREDNS_IP
}
EOT

kubectl patch configmap coredns -n kube-system -p "{\"data\":{\"Corefile\": \"$(cat /root/dns-settings.txt | sed ':a;N;$!ba;s/\n/\\n/g')\"}}"
rm /root/dns-settings.txt
