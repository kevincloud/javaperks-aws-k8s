resource "aws_dynamodb_table" "customer-cart" {
    name = "jp-k8s-customer-cart-${var.unit_prefix}"
    billing_mode = "PROVISIONED"
    read_capacity = 20
    write_capacity = 20
    hash_key = "SessionId"
    range_key = "ProductId"
    
    attribute {
        name = "SessionId"
        type = "S"
    }
    
    attribute {
        name = "ProductId"
        type = "S"
    }
    
    global_secondary_index {
        name = "SessionIndex"
        hash_key = "SessionId"
        write_capacity = 10
        read_capacity = 10
        projection_type = "ALL"
    }

    tags = {
        Name = "jp-k8s-customer-cart-${var.unit_prefix}"
        "kubernetes.io/cluster/javaperks" = "owned"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}
