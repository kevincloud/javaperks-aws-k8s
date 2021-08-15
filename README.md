# Java Perks Online Store

### A demonstration of HashiCorp Terraform, Vault, Consul, and Nomad

Java Perks is a ficticious wholesale company who sells equipment and supplies to coffee shops around the US. All business is conducted through their online store, so quickly responding to market trends and customer demands is critical.

To get started with this demo, copy the terraform.tfvars.example and fill in with your own information. The variables are as follows:

* `aws_region`: Region to deploy the demo to. Defaults to `us-east-1`
* `aws_azs`: Availability zones to use for the worker nodes. Defaults to 3
* `aws_kms_key_id`: A KMS key is needed for Vault's auto unseal. You'll need to provide a KMS key in the specified region
* `key_pair`: This is the EC2 key pair you created in order to SSH into your EC2 instance
* `mysql_user`: Admin username for the MySQL instance. Defaults to `root`
* `mysql_pass`: Password for the MySQL admin user. Defaults to `MySecretPassword`
* `mysql_database`: Name of the database for the demo. Defaults to `javaperks`
* `instance_size`: Size of the AWS instances for the worker nodes. Defaults to `t3.small`
* `num_worker_nodes`: Number of Kubernetes worker nodes
* `consul_license_key`: License key for Consul Enterprise. Optional
* `vault_license_key`: License key for Vault Enterprise. Optional
* `unit_prefix`: A unique identifier which is appended to each resource name to avoid name clashes
* `ldap_pass`: LDAP admin password. Defaults to `MySecretPassword`
* `git_branch`: Branch to use for cloning install scripts. Defaults to `master`
* `owner_email`: Your email address. Used for tagging instances
* `vault_dl_url`: Used as a Vault client for CLI use. Defaults to 1.4
* `zoneid`: Route53 Zone ID for LBs to DNS. Default is empty

### Application Repos

Java Perks is comprised of 6 total applications:

Online Store (Frontend):
https://github.com/kevincloud/javaperks-online-store

Customer data API, MySQL backend:
https://github.com/kevincloud/javaperks-customer-api

Shopping cart API, DynamoDB backend:
https://github.com/kevincloud/javaperks-cart-api

Order API, DynamoDB backend:
https://github.com/kevincloud/javaperks-order-api

Product API, DynamoDB backend:
https://github.com/kevincloud/javaperks-product-api

Authentication API, Vault/LDAP backend:
https://github.com/kevincloud/javaperks-auth-api
