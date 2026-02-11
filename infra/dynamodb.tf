resource "aws_dynamodb_table" "orders" {
  name             = "${var.project_name}-${var.environment}-orders"
  billing_mode     = "PROVISIONED"
  read_capacity    = var.dynamodb_read_capacity
  write_capacity   = var.dynamodb_write_capacity
  hash_key         = "order_id"
  range_key        = "created_at"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "customer_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Global Secondary Index by customer
  global_secondary_index {
    name            = "customer_id-created_at-index"
    hash_key        = "customer_id"
    range_key       = "created_at"
    read_capacity   = var.dynamodb_read_capacity
    write_capacity  = var.dynamodb_write_capacity
    projection_type = "ALL"
  }

  # Global Secondary Index by status
  global_secondary_index {
    name            = "status-created_at-index"
    hash_key        = "status"
    range_key       = "created_at"
    read_capacity   = var.dynamodb_read_capacity
    write_capacity  = var.dynamodb_write_capacity
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }

  tags = var.tags
}
