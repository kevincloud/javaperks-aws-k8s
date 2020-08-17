resource "aws_db_subnet_group" "dbsubnets" {
    name = "jp-k8s-db-subnet-${var.unit_prefix}"
    subnet_ids = aws_subnet.private-subnet.*.id

    tags = {
        "kubernetes.io/cluster/javaperks" = "owned"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}


resource "aws_db_instance" "jp-k8s-mysql" {
    allocated_storage = 10
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.${var.instance_size}"
    name = "jpk8s${var.unit_prefix}"
    identifier = "jpk8sdb${var.unit_prefix}"
    db_subnet_group_name = aws_db_subnet_group.dbsubnets.name
    vpc_security_group_ids = [aws_security_group.jp-k8s-mysql-sg.id]
    username = var.mysql_user
    password = var.mysql_pass
    skip_final_snapshot = true

    tags = {
        "kubernetes.io/cluster/javaperks" = "owned"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}

resource "aws_security_group" "jp-k8s-mysql-sg" {
    name = "jp-k8s-mysql-sg-${var.unit_prefix}"
    description = "mysql security group"
    vpc_id = aws_vpc.primary-vpc.id

    tags = {
        "kubernetes.io/cluster/javaperks" = "owned"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
