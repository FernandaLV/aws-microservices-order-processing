resource "aws_sqs_queue" "order_queue" {
  name                      = "${var.project_name}-queue"
  message_retention_seconds = var.sqs_message_retention_period
  visibility_timeout_seconds = var.sqs_visibility_timeout

  tags = var.tags
}

resource "aws_sqs_queue_policy" "order_queue_policy" {
  queue_url = aws_sqs_queue.order_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.order_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_notifications.arn
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic" "order_notifications" {
  name = "${var.project_name}-notifications"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "order_queue" {
  topic_arn            = aws_sns_topic.order_notifications.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.order_queue.arn
  raw_message_delivery = true
}
