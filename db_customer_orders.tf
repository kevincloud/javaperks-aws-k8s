resource "aws_dynamodb_table" "customer-order-table" {
    name = "jp-k8s-customer-orders-${var.unit_prefix}"
    billing_mode = "PROVISIONED"
    read_capacity = 20
    write_capacity = 20
    hash_key = "OrderId"
    
    attribute {
        name = "OrderId"
        type = "S"
    }
    
    attribute {
        name = "CustomerId"
        type = "S"
    }

    global_secondary_index {
        name = "CustomerIndex"
        hash_key = "CustomerId"
        write_capacity = 10
        read_capacity = 10
        projection_type = "ALL"
    }

    tags = {
        Name = "jp-k8s-customer-orders-${var.unit_prefix}"
        "kubernetes.io/cluster/javaperks" = "owned"
        Owner = var.owner
        Region = var.hc_region
        Purpose = var.purpose
        TTL = var.ttl
    }
}
