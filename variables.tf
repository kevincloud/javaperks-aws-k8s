variable "aws_access_key" {
    type = string
    description = "AWS Access Key"
}

variable "aws_secret_key" {
    type = string
    description = "AWS Secret Key"
}

variable "aws_session_token" {
    type = string
    description = "AWS Session Token"
}

variable "aws_region" {
    type = string
    description = "AWS Region"
    default = "us-east-1"
}

variable "aws_azs" {
    type = list(string)
    description = "The availability zones to be used for this cluster"
    default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "aws_kms_key_id" {
    type = string
    description = "AWS KMS Key for Unsealing"
}

variable "key_pair" {
    type = string
    description = "Key pair used to login to the instance"
}

variable "unit_prefix" {
    type = string
    description = "A unique identifier to name each resource"
}

variable "mysql_user" {
    type = string
    description = "Root user name for the MySQL server backend for Vault"
    default = "root"
}

variable "mysql_pass" {
    type = string
    description = "Root user password for the MySQL server backend for Vault"
    default = "MySecretPassword"
}

variable "mysql_database" {
    type = string
    description = "Name of database for Java Perks"
    default = "javaperks"
}

variable "instance_size" {
    type = string
    description = "The instance size to be used for each machine in the cluster"
    default = "t3.small"
}

variable "consul_license_key" {
    type = string
    description = "License key for Consul Enterprise"
}

variable "vault_license_key" {
    type = string
    description = "License key for Vault Enterprise"
}

variable "ldap_pass" {
    type = string
    description = "Admin password for the OpenLDAP server"
    default = "MySecretPassword"
}

variable "git_branch" {
    type = string
    description = "Branch used for this instance"
    default = "master"
}


variable "num_worker_nodes" {
    type = number
    description = "The number of worker nodes to spin up"
    default = 3

    # validation {
    #     condition = var.num_worker_nodes >= 3
    #     error_message = "You must specify a minimum of 3 worker nodes"
    # }
}

variable "vault_dl_url" {
    type = string
    description = "The URL to download Vault from"
    default = "https://releases.hashicorp.com/vault/1.4.0/vault_1.4.0_linux_amd64.zip"
}

variable "zoneid" {
    type = string
    description = "Zone ID for Route 53"
    default = ""
}

variable "consul_helm" {
    type = string
    description = "Helm chart to use to install Consul"
    default = "consul"
}

variable "vault_helm" {
    type = string
    description = "Helm chart to use to install Vault"
    default = "vault"
}

variable "owner" {
    description = ""
}

variable "hc_region" {
    description = ""
}

variable "purpose" {
    description = ""
}

variable "ttl" {
    description = ""
}
