resource "aws_instance" "jp-k8s-worker" {
    count = var.num_worker_nodes
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_size
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.jp-k8s-worker-sg.id]
    user_data = templatefile("${path.module}/scripts/worker_install.sh", {
        NODE_ID = count.index + 1
    })
    subnet_id = aws_subnet.public-subnet[count.index%length(var.aws_azs)].id
    iam_instance_profile = aws_iam_instance_profile.jp-k8s-main-profile.id
    private_ip = "10.0.${count.index%length(var.aws_azs)+1}.${count.index + 100}"

    tags = {
        Name = "jp-k8s-worker-${var.unit_prefix}-${count.index + 1}"
        "kubernetes.io/cluster/javaperks" = "owned"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}

resource "aws_security_group" "jp-k8s-worker-sg" {
    name = "jp-k8s-worker-sg-${var.unit_prefix}"
    description = "webserver security group"
    vpc_id = aws_vpc.primary-vpc.id
    tags = {
        "kubernetes.io/cluster/javaperks" = "owned"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
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
        from_port = 8200
        to_port = 8200
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
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
        from_port = 10250
        to_port = 10250
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    ingress {
        from_port = 30000
        to_port = 32767
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
