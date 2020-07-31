resource "aws_instance" "jp-k8s-master" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t3.large"
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.jp-k8s-master-sg.id]
    subnet_id = aws_subnet.public-subnet[0].id
    iam_instance_profile = aws_iam_instance_profile.jp-k8s-main-profile.id
    private_ip = "10.0.1.10"
    user_data = templatefile("${path.module}/scripts/installer.sh", {
        MYSQL_HOST = aws_db_instance.jp-k8s-mysql.address
        MYSQL_USER = var.mysql_user
        MYSQL_PASS = var.mysql_pass
        MYSQL_DB = var.mysql_database
        AWS_ACCESS_KEY = var.aws_access_key
        AWS_SECRET_KEY = var.aws_secret_key
        AWS_KMS_KEY_ID = var.aws_kms_key_id
        REGION = var.aws_region
        S3_BUCKET = aws_s3_bucket.staticimg.id
        VAULT_LICENSE = var.vault_license_key
        CONSUL_LICENSE = var.consul_license_key
        TABLE_PRODUCT = aws_dynamodb_table.product-data-table.id
        TABLE_CART = aws_dynamodb_table.customer-cart.id
        TABLE_ORDER = aws_dynamodb_table.customer-order-table.id
        BRANCH_NAME = var.git_branch
        LDAP_ADMIN_PASS = var.ldap_pass
        VAULT_DL_URL = var.vault_dl_url
        ZONE_ID = var.zoneid
    })

    tags = {
        Name = "jp-k8s-server-${var.unit_prefix}"
        # TTL = "-1"
        owner = var.owner_email
        "kubernetes.io/cluster/javaperks" = "owned"
    }
}

resource "aws_security_group" "jp-k8s-master-sg" {
    name = "jp-k8s-master-sg-${var.unit_prefix}"
    description = "webserver security group"
    vpc_id = aws_vpc.primary-vpc.id
    tags = {
        "kubernetes.io/cluster/javaperks" = "owned"
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 2379
        to_port = 2380
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 6443
        to_port = 6443
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 6781
        to_port = 6784
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 6783
        to_port = 6784
        protocol = "udp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 8300
        to_port = 8302
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 8301
        to_port = 8302
        protocol = "udp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 8500
        to_port = 8500
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 8600
        to_port = 8600
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 8600
        to_port = 8600
        protocol = "udp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 9090
        to_port = 9090
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 10250
        to_port = 10252
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 10255
        to_port = 10255
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
