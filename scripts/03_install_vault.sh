#!/bin/bash

# Install Vault
cd /root
git clone https://github.com/hashicorp/vault-helm.git
sudo bash -c "cat >/root/helm-vault-values.yaml" <<EOT
# helm-vault-values.yaml
server:
  standalone:
    enabled: true
    config: |
      ui = true

      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      storage "file" {
        path = "/vault/data"
      }
      seal "awskms" {
        region = "$AWS_REGION"
        kms_key_id = "$AWS_KMS_KEY_ID"
      }
  service:
    enabled: true
  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: null
    accessMode: ReadWriteOnce
ui:
  enabled: true
  serviceType: LoadBalancer
EOT

echo "Initializing Vault (this can take several minutes)..."
helm install -f helm-vault-values.yaml hc-vault ./vault-helm

sleep 5

while [[ ! -z $(kubectl get pods | grep hc-vault | sed -n '1d; /Running/ !p') ]]; do
    echo "...waiting for pod..."
    sleep 2
done

kubectl exec hc-vault-0 -- /bin/vault operator init -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1 > /root/vault-init.txt 2>/root/verr.txt
while [[ -z $(cat /root/vault-init.txt) ]]; do
    echo "...initializing vault..."
    sleep 2
    kubectl exec hc-vault-0 -- /bin/vault operator init -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1 > /root/vault-init.txt 2>/root/verr.txt
done

echo "Vault successfully initialized!"
echo "Setting up data and variables..."

sleep 5

echo "Initializing and setting up environment variables..."
export VAULT_ADDR="http://$(kubectl get service hc-vault-ui -o=custom-columns=EXTERNAL-IP:.status.loadBalancer.ingress[0].hostname | sed -n '1d; p'):8200"
export CONSUL_HTTP_ADDR=$(kubectl get service hc-consul-consul-ui -o=custom-columns=EXTERNAL-IP:.status.loadBalancer.ingress[0].hostname | sed -n '1d; p')

sleep 10

echo "Extracting vault root token..."
export VAULT_TOKEN=$(cat /root/vault-init.txt | sed -n -e '/^Initial Root Token/ s/.*\: *//p')
echo "Root token is $VAULT_TOKEN"
kubectl exec hc-consul-consul-server-0 -- curl -s --request PUT --data $VAULT_TOKEN http://127.0.0.1:8500/v1/kv/service/vault/root-token
echo "Extracting vault recovery key..."
export RECOVERY_KEY=$(cat /root/vault-init.txt | sed -n -e '/^Recovery Key 1/ s/.*\: *//p')
echo "Recovery key is $RECOVERY_KEY"
kubectl exec hc-consul-consul-server-0 -- curl -s --request PUT --data $VAULT_TOKEN http://127.0.0.1:8500/v1/kv/service/vault/recovery-key

echo "export VAULT_ADDR=http://localhost:8200" >> /home/ubuntu/.profile
echo "export VAULT_TOKEN=$VAULT_TOKEN" >> /home/ubuntu/.profile
echo "export VAULT_ADDR=http://localhost:8200" >> /root/.profile
echo "export VAULT_TOKEN=$VAULT_TOKEN" >> /root/.profile

echo "Configuring Vault..."

# # Enable auditing
# curl -s \
#     --header "X-Vault-Token: $VAULT_TOKEN" \
#     --request PUT \
#     --data "{ \"descriptiopn\": \"Primary Audit\", \"type\": \"file\", \"options\": { \"file_path\": \"/var/log/vault/log\" } }" \
#     $VAULT_ADDR/v1/sys/audit/main-audit

# Enable LDAP authentication
echo "Enable LDAP auth"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "ldap" }' \
    $VAULT_ADDR/v1/sys/auth/ldap

# Enable dynamic database creds
echo "Enable dynamic secrets for custdbcreds"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "database" }' \
    $VAULT_ADDR/v1/sys/mounts/custdbcreds

# Configure connection
echo "Configure custdbcreds"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{ \"plugin_name\": \"mysql-database-plugin\", \"allowed_roles\": \"cust-api-role\", \"connection_url\": \"{{username}}:{{password}}@tcp($MYSQL_HOST:3306)/\", \"username\": \"$MYSQL_USER\", \"password\": \"$MYSQL_PASS\" }" \
    $VAULT_ADDR/v1/custdbcreds/config/custapidb

echo "Add role for custdbcreds"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{ \"db_name\": \"custapidb\", \"creation_statements\": \"CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '{{name}}'@'%';\", \"default_ttl\": \"5m\", \"max_ttl\": \"24h\" }" \
    $VAULT_ADDR/v1/custdbcreds/roles/cust-api-role

# Enable secrets mount point for kv2
echo "Enable KV for usercreds"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "kv", "options": { "version": "2" } }' \
    $VAULT_ADDR/v1/sys/mounts/usercreds

echo "Enable KV for secret"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "kv", "options": { "version": "2" } }' \
    $VAULT_ADDR/v1/sys/mounts/secret

# add usernames and passwords
echo "Add users"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "jthomp4423@example.com", "password": "SuperSecret1", "customerno": "CS100312" } }' \
    $VAULT_ADDR/v1/usercreds/data/jthomp4423@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "wilson@example.com", "password": "SuperSecret1", "customerno": "CS106004" } }' \
    $VAULT_ADDR/v1/usercreds/data/wilson@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "tommy6677@example.com", "password": "SuperSecret1", "customerno": "CS101438" } }' \
    $VAULT_ADDR/v1/usercreds/data/tommy6677@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "mmccann1212@example.com", "password": "SuperSecret1", "customerno": "CS210895" } }' \
    $VAULT_ADDR/v1/usercreds/data/mmccann1212@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "cjpcomp@example.com", "password": "SuperSecret1", "customerno": "CS122955" } }' \
    $VAULT_ADDR/v1/usercreds/data/cjpcomp@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "jjhome7823@example.com", "password": "SuperSecret1", "customerno": "CS602934" } }' \
    $VAULT_ADDR/v1/usercreds/data/jjhome7823@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "clint.mason312@example.com", "password": "SuperSecret1", "customerno": "CS157843" } }' \
    $VAULT_ADDR/v1/usercreds/data/clint.mason312@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "greystone89@example.com", "password": "SuperSecret1", "customerno": "CS523484" } }' \
    $VAULT_ADDR/v1/usercreds/data/greystone89@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "runwayyourway@example.com", "password": "SuperSecret1", "customerno": "CS658871" } }' \
    $VAULT_ADDR/v1/usercreds/data/runwayyourway@example.com

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"data": { "username": "olsendog1979@example.com", "password": "SuperSecret1", "customerno": "CS103393" } }' \
    $VAULT_ADDR/v1/usercreds/data/olsendog1979@example.com

# Add policies
echo "Add dbcreds policy"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data '{ "policy": "path \"secret/data/dbhost\" {\n  capabilities = [\"read\"]\n}\n\npath \"custdbcreds/creds/*\" {\n  capabilities = [\"read\"]\n}\n" }' \
    $VAULT_ADDR/v1/sys/policy/dbcreds

echo "Add logincreds policy"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data '{ "policy": "path \"usercreds/data/*\" {\n  capabilities = [\"read\"]\n }\n" }' \
    $VAULT_ADDR/v1/sys/policy/logincreds

echo "Add storecreds policy"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data '{ "policy": "path \"usercreds/*\" {\n  capabilities = [ \"read\", \"create\", \"delete\", \"update\", \"list\" ]\n }\n\n path \"transit/*\" {\n  capabilities = [ \"read\", \"create\", \"delete\", \"update\", \"list\" ]\n }\n" }' \
    $VAULT_ADDR/v1/sys/policy/storecreds

# Setup Kubernetes
sudo bash -c "cat >/root/vault-auth-service-account.yaml" <<EOT
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: default
EOT

kubectl apply -f /root/vault-auth-service-account.yaml

export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode | sed ':a;N;$!ba;s/\n/\\n/g')

echo "Enable Kubernetes auth"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{ "type": "kubernetes" }' \
    $VAULT_ADDR/v1/sys/auth/kubernetes

echo "Configure Kubernetes auth"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{ \"kubernetes_host\": \"https://$CLIENT_IP:6443\", \"kubernetes_ca_cert\": \"$SA_CA_CRT\", \"token_reviewer_jwt\": \"$SA_JWT_TOKEN\" }" \
    $VAULT_ADDR/v1/auth/kubernetes/config

echo "Create Kubernetes role"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{ \"bound_service_account_names\": \"vault-auth\", \"bound_service_account_namespaces\": \"*\", \"policies\": \"dbcreds,logincreds,storecreds\", \"ttl\": \"24h\" }" \
    $VAULT_ADDR/v1/auth/kubernetes/role/cust-api

# Additional configs
echo "Add AWS Credentials"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{\"data\": { \"aws_access_key\": \"$AWS_ACCESS_KEY\", \"aws_secret_key\": \"$AWS_SECRET_KEY\", \"aws_region\": \"$AWS_REGION\" } }" \
    $VAULT_ADDR/v1/secret/data/aws

echo "Add root token"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{\"data\": { \"token\": \"$VAULT_TOKEN\" } }" \
    $VAULT_ADDR/v1/secret/data/roottoken

echo "Add database credentials"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{\"data\": { \"address\": \"$MYSQL_HOST\", \"database\": \"$MYSQL_DB\", \"username\": \"$MYSQL_USER\", \"password\": \"$MYSQL_PASS\" } }" \
    $VAULT_ADDR/v1/secret/data/dbhost

echo "Enable transit engine..."
# enable transit
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type":"transit"}' \
    $VAULT_ADDR/v1/sys/mounts/transit

echo "Create account key..."
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    $VAULT_ADDR/v1/transit/keys/account

echo "Create payment key..."
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    $VAULT_ADDR/v1/transit/keys/payment

curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data "{ \"url\": \"ldap://${CLIENT_IP}\", \"userattr\": \"uid\", \"userdn\": \"ou=Customers,dc=javaperks,dc=local\", \"groupdn\": \"ou=Customers,dc=javaperks,dc=local\", \"groupfilter\": \"(&(objectClass=groupOfNames)(member={{.UserDN}}))\", \"groupattr\": \"cn\", \"binddn\": \"${LDAP_ADMIN_USER}\", \"bindpass\": \"${LDAP_ADMIN_PASS}\" }" \
    $VAULT_ADDR/v1/auth/ldap/config

export VAULT_ADDR="http://$(kubectl get service hc-vault-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8200"

curl -sfLo "/root/vault.zip" "${VAULT_DL_URL}"
unzip /root/vault.zip -d /usr/local/bin/
sleep 3
rm -rf /root/vault.zip

echo "Vault installation complete."

