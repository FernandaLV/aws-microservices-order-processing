# Quando subir SNS, revisar o aquivo do SQS

resource "aws_sns_topic" "order_notifications" {
  name = "${var.project_name}-notifications"

  tags = var.tags
}

resource "aws_sns_topic_policy" "order_notifications_policy" {
  arn = aws_sns_topic.order_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.order_notifications.arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "order_queue" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_queue.arn

  raw_message_delivery = true
}
