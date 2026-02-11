output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.lambda.invoke_url
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.order_queue.url
}

output "sqs_queue_arn" {
  description = "SQS queue ARN"
  value       = aws_sqs_queue.order_queue.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.order_notifications.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.orders.name
}

output "step_functions_arn" {
  description = "Step Functions state machine ARN"
  value       = aws_sfn_state_machine.order_workflow.arn
}

output "lambda_enqueue_arn" {
  description = "Enqueue Order Lambda ARN"
  value       = aws_lambda_function.enqueue_order.arn
}

output "lambda_process_queue_arn" {
  description = "Process Queue Lambda ARN"
  value       = aws_lambda_function.process_queue.arn
}

output "lambda_process_payment_arn" {
  description = "Process Payment Lambda ARN"
  value       = aws_lambda_function.process_payment.arn
}

output "lambda_update_order_arn" {
  description = "Update Order Lambda ARN"
  value       = aws_lambda_function.update_order.arn
}
