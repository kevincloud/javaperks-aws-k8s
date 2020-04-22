#!/bin/bash

VAULT_ADDRESS=$(kubectl get service hc-vault-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
# Create mysql database
echo "Creating database..."
python3 /root/javaperks-aws-k8s/scripts/create_db.py $MYSQL_HOST $MYSQL_USER $MYSQL_PASS $VAULT_TOKEN $AWS_REGION $VAULT_ADDRESS

# load product data
echo "Loading product data..."
python3 /root/javaperks-aws-k8s/scripts/product_load.py $TABLE_PRODUCT $AWS_REGION

# upload product-app images
echo "Cloning product images..."
git clone https://github.com/kevincloud/javaperks-product-api.git /root/javaperks-product-api

# Upload images to S3
echo "Uploading product images..."
aws s3 cp /root/javaperks-product-api/images/ s3://$S3_BUCKET/images/ --recursive --acl public-read

# Clean up
rm -rf /root/javaperks-product-api


# kubectl run k8s-shell --rm -i --tty --serviceaccount=vault-auth --image ubuntu:latest

# https://releases.hashicorp.com/vault/1.4.0/vault_1.4.0_linux_amd64.zip
