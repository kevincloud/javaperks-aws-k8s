data "aws_iam_policy_document" "jp-k8s-assume-role" {
    statement {
        effect  = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "jp-k8s-main-access-doc-data" {
    statement {
        sid       = "FullAccess"
        effect    = "Allow"
        resources = ["*"]

        actions = [
            "ecr:*",
            "ecr:GetAuthorizationToken",
            "ec2:*",
            "ec2:Describe*",
            "ec2messages:GetMessages",
            "elasticloadbalancing:*",
            "autoscaling:DescribeAutoScalingGroup",
            "autoscaling:UpdateAutoScalingGroup",
            "autoscaling:DescribeTags",
            "ssm:UpdateInstanceInformation",
            "ssm:ListInstanceAssociations",
            "ssm:ListAssociations",
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:DescribeKey",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            "rds-db:*",
            "dynamodb:*"
         ]
    }
}

data "aws_iam_policy_document" "jp-k8s-main-tag-doc-data" {
    statement {
        effect = "Allow"
        resources = ["arn:aws:ec2:*:*:network-interface/*"]
        actions = [
            "ec2:CreateTags"
        ]
    }
}

data "aws_iam_policy_document" "jp-k8s-main-inst-doc-data" {
    statement {
        effect = "Allow"
        resources = ["arn:aws:ec2:*:*:instance/*"]
        actions = [
            "ec2:AttachVolume",
            "ec2:DetachVolume"
        ]
    }
}

resource "aws_iam_policy" "jp-k8s-main-access-doc" {
    name = "jp-k8s-access-policy-${var.unit_prefix}"
    policy = data.aws_iam_policy_document.jp-k8s-main-access-doc-data.json
}

resource "aws_iam_policy" "jp-k8s-main-tag-doc" {
    name = "jp-k8s-tag-policy-${var.unit_prefix}"
    policy = data.aws_iam_policy_document.jp-k8s-main-tag-doc-data.json
}

resource "aws_iam_policy" "jp-k8s-main-inst-doc" {
    name = "jp-k8s-inst-policy-${var.unit_prefix}"
    policy = data.aws_iam_policy_document.jp-k8s-main-inst-doc-data.json
}

resource "aws_iam_role" "jp-k8s-main-access-role" {
    name               = "jp-k8s-access-role-${var.unit_prefix}"
    assume_role_policy = data.aws_iam_policy_document.jp-k8s-assume-role.json

    tags = {
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}

resource "aws_iam_role_policy_attachment" "jp-k8s-main-access-policy-1" {
    role   = aws_iam_role.jp-k8s-main-access-role.id
    policy_arn = aws_iam_policy.jp-k8s-main-access-doc.arn
}

resource "aws_iam_role_policy_attachment" "jp-k8s-main-access-policy-2" {
    role   = aws_iam_role.jp-k8s-main-access-role.id
    policy_arn = aws_iam_policy.jp-k8s-main-tag-doc.arn
}

resource "aws_iam_role_policy_attachment" "jp-k8s-main-access-policy-3" {
    role   = aws_iam_role.jp-k8s-main-access-role.id
    policy_arn = aws_iam_policy.jp-k8s-main-inst-doc.arn
}

resource "aws_iam_instance_profile" "jp-k8s-main-profile" {
    name = "jp-k8s-access-profile-${var.unit_prefix}"
    role = aws_iam_role.jp-k8s-main-access-role.name
}
