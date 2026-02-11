data "archive_file" "enqueue_order_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/enqueue_order"
  output_path = "${path.module}/.terraform/enqueue_order.zip"
}

data "archive_file" "process_queue_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/process_queue"
  output_path = "${path.module}/.terraform/process_queue.zip"
}

data "archive_file" "process_payment_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/process_payment"
  output_path = "${path.module}/.terraform/process_payment.zip"
}

data "archive_file" "update_order_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/update_order"
  output_path = "${path.module}/.terraform/update_order.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.order_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.orders.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.order_notifications.arn
      }
    ]
  })
}

# Lambda: Enqueue Order
resource "aws_lambda_function" "enqueue_order" {
  filename            = data.archive_file.enqueue_order_zip.output_path
  function_name       = "${var.project_name}-enqueue-order"
  role                = aws_iam_role.lambda_role.arn
  handler             = "handler.lambda_handler"
  source_code_hash    = data.archive_file.enqueue_order_zip.output_base64sha256
  runtime             = "python3.11"
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory_size

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.order_queue.url
      TABLE_NAME = aws_dynamodb_table.orders.name
    }
  }

  tags = var.tags
}

# Lambda: Process Queue
resource "aws_lambda_function" "process_queue" {
  filename            = data.archive_file.process_queue_zip.output_path
  function_name       = "${var.project_name}-process-queue"
  role                = aws_iam_role.lambda_role.arn
  handler             = "handler.lambda_handler"
  source_code_hash    = data.archive_file.process_queue_zip.output_base64sha256
  runtime             = "python3.11"
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory_size

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.order_queue.url
      TABLE_NAME = aws_dynamodb_table.orders.name
    }
  }

  tags = var.tags
}

# Lambda: Process Payment
resource "aws_lambda_function" "process_payment" {
  filename            = data.archive_file.process_payment_zip.output_path
  function_name       = "${var.project_name}-process-payment"
  role                = aws_iam_role.lambda_role.arn
  handler             = "handler.lambda_handler"
  source_code_hash    = data.archive_file.process_payment_zip.output_base64sha256
  runtime             = "python3.11"
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory_size

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.orders.name
      SNS_TOPIC_ARN = aws_sns_topic.order_notifications.arn
    }
  }

  tags = var.tags
}

# Lambda: Update Order
resource "aws_lambda_function" "update_order" {
  filename            = data.archive_file.update_order_zip.output_path
  function_name       = "${var.project_name}-update-order"
  role                = aws_iam_role.lambda_role.arn
  handler             = "handler.lambda_handler"
  source_code_hash    = data.archive_file.update_order_zip.output_base64sha256
  runtime             = "python3.11"
  timeout             = var.lambda_timeout
  memory_size         = var.lambda_memory_size

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.orders.name
    }
  }

  tags = var.tags
}

# Event source mapping: SQS to Lambda
resource "aws_lambda_event_source_mapping" "sqs_to_process_queue" {
  event_source_arn = aws_sqs_queue.order_queue.arn
  function_name    = aws_lambda_function.process_queue.arn
  batch_size       = 10
}
