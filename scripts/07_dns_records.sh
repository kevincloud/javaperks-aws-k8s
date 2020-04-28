#!/bin/bash

if [ -z $ZONE_ID ]; then
    exit 1
fi

mkdir /root/zones

HOSTED_ZONE=$(aws route53 get-hosted-zone --id $ZONE_ID --region=$AWS_REGION | jq -r .HostedZone.Name)

# Java Perks home page
JAVAPERKS_LB_ADDR=$(kubectl get service front-end -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
JAVAPERKS_LB_NAME=$(echo $JAVAPERKS_LB_ADDR | awk -F"-" '{print $1}')
JAVAPERKS_LB_ZONEID=$(aws elb describe-load-balancers --load-balancer-names $JAVAPERKS_LB_NAME --region=$AWS_REGION | jq -r .LoadBalancerDescriptions[0].CanonicalHostedZoneNameID)
bash -c "cat >/root/zones/javaperks-home.json" <<EOT
{
    "Comment": "Hostname for JavaPerks website",
    "Changes": [
        {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "javaperks-home.$HOSTED_ZONE",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "$JAVAPERKS_LB_ZONEID",
                    "DNSName": "dualstack.$JAVAPERKS_LB_ADDR",
                    "EvaluateTargetHealth": false
                }
            }
        }
    ]
}
EOT

# Consul
CONSUL_LB_ADDR=$(kubectl get service hc-consul-consul-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
CONSUL_LB_NAME=$(echo $CONSUL_LB_ADDR | awk -F"-" '{print $1}')
CONSUL_LB_ZONEID=$(aws elb describe-load-balancers --load-balancer-names $CONSUL_LB_NAME --region=$AWS_REGION | jq -r .LoadBalancerDescriptions[0].CanonicalHostedZoneNameID)
bash -c "cat >/root/zones/javaperks-consul.json" <<EOT
{
    "Comment": "Hostname for JavaPerks Consul cluster",
    "Changes": [
        {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "javaperks-consul.$HOSTED_ZONE",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "$CONSUL_LB_ZONEID",
                    "DNSName": "dualstack.$CONSUL_LB_ADDR",
                    "EvaluateTargetHealth": false
                }
            }
        }
    ]
}
EOT

# Vault
VAULT_LB_ADDR=$(kubectl get service hc-vault-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
VAULT_LB_NAME=$(echo $VAULT_LB_ADDR | awk -F"-" '{print $1}')
VAULT_LB_ZONEID=$(aws elb describe-load-balancers --load-balancer-names $VAULT_LB_NAME --region=$AWS_REGION | jq -r .LoadBalancerDescriptions[0].CanonicalHostedZoneNameID)
bash -c "cat >/root/zones/javaperks-vault.json" <<EOT
{
    "Comment": "Hostname for JavaPerks Vault instance",
    "Changes": [
        {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "javaperks-vault.$HOSTED_ZONE",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "$VAULT_LB_ZONEID",
                    "DNSName": "dualstack.$VAULT_LB_ADDR",
                    "EvaluateTargetHealth": false
                }
            }
        }
    ]
}
EOT

# Kubernetes dashboard
KUBEDASH_LB_ADDR=$(kubectl get service kubernetes-dashboard -n kubernetes-dashboard -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
KUBEDASH_LB_NAME=$(echo $KUBEDASH_LB_ADDR | awk -F"-" '{print $1}')
KUBEDASH_LB_ZONEID=$(aws elb describe-load-balancers --load-balancer-names $KUBEDASH_LB_NAME --region=$AWS_REGION | jq -r .LoadBalancerDescriptions[0].CanonicalHostedZoneNameID)
bash -c "cat >/root/zones/javaperks-kubedash.json" <<EOT
{
    "Comment": "Hostname for JavaPerks Kubernetes dashboard",
    "Changes": [
        {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "javaperks-kubedash.$HOSTED_ZONE",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "$KUBEDASH_LB_ZONEID",
                    "DNSName": "dualstack.$KUBEDASH_LB_ADDR",
                    "EvaluateTargetHealth": false
                }
            }
        }
    ]
}
EOT

aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file:///root/zones/javaperks-home.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file:///root/zones/javaperks-consul.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file:///root/zones/javaperks-vault.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file:///root/zones/javaperks-kubedash.json

bash -c "cat >>/root/javaperks-aws-k8s/scripts/uninstall.sh" <<EOT

# Delete DNS records
sed -i 's/CREATE/DELETE/g' /root/zones/javaperks-home.json
sed -i 's/CREATE/DELETE/g' /root/zones/javaperks-consul.json
sed -i 's/CREATE/DELETE/g' /root/zones/javaperks-vault.json
sed -i 's/CREATE/DELETE/g' /root/zones/javaperks-kubedash.json

aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file:///root/zones/javaperks-home.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file:///root/zones/javaperks-consul.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file:///root/zones/javaperks-vault.json
aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file:///root/zones/javaperks-kubedash.json
EOT
