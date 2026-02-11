resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-step-functions-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.process_payment.arn,
          aws_lambda_function.update_order.arn
        ]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "order_workflow" {
  name       = "${var.project_name}-workflow"
  role_arn   = aws_iam_role.step_functions_role.arn
  definition = templatefile("${path.module}/../statemachine/order_workflow.asl.json", {
    process_payment_arn = aws_lambda_function.process_payment.arn
    update_order_arn    = aws_lambda_function.update_order.arn
  })

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.step_functions_policy
  ]
}
