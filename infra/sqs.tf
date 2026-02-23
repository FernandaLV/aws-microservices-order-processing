resource "aws_sqs_queue" "order_queue" {
  name                       = "${var.project_name}-queue"
  message_retention_seconds  = var.sqs_message_retention_period
  visibility_timeout_seconds = var.sqs_visibility_timeout

  tags = var.tags
}

