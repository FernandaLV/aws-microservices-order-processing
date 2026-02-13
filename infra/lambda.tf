data "archive_file" "process_queue_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/process_queue"
  output_path = "${path.module}/.terraform/process_queue.zip"
}

# IAM role and policy for Lambda to access SQS and CloudWatch Logs
resource "aws_iam_role" "lambda_sqs_role" {
  name = "${var.project_name}-lambda-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name = "${var.project_name}-lambda-sqs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.order_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_sqs_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
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

  tags = var.tags
}

# Event source mapping: SQS to Lambda
resource "aws_lambda_event_source_mapping" "sqs_to_process_queue" {
  event_source_arn = aws_sqs_queue.order_queue.arn
  function_name    = aws_lambda_function.process_queue.arn
  batch_size       = 1 #maximum number of records that Lambda will retrieve from a stream or queue and send to your function in a single invocation
}
