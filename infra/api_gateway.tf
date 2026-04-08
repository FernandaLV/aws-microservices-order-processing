# API Gateway para o serviço de pedidos
resource "aws_api_gateway_rest_api" "orders_api" {
  name = "${var.project_name}-orders-api"
}
# Recurso para o endpoint /orders
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  parent_id   = aws_api_gateway_rest_api.orders_api.root_resource_id
  path_part   = "orders"
}


# Modelo para validação do corpo da requisição
resource "aws_api_gateway_model" "order_model" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  name         = "OrderModel"
  content_type = "application/json"

  schema = jsonencode({
    type = "object"
    required = ["orderId", "product", "price"]

    properties = {
      orderId = {
        type = "string"
      }
      product = {
        type = "string"
      }
      price = {
        type = "number"
      }
    }
  })
}

# Validator para validar o corpo da requisição usando o modelo definido
resource "aws_api_gateway_request_validator" "validator" {
  name                        = "validate-body"
  rest_api_id                 = aws_api_gateway_rest_api.orders_api.id
  validate_request_body       = true
  validate_request_parameters = false
}


# Método POST para criar um novo pedido
resource "aws_api_gateway_method" "post_orders" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
  
  # Configuração para usar o modelo de validação
  request_models = {
    "application/json" = aws_api_gateway_model.order_model.name
  }

  # Configuração para usar o request validator
  request_validator_id = aws_api_gateway_request_validator.validator.id
}


# Role IAM - Integração do método POST com o Lambda de criação de pedidos
resource "aws_iam_role" "api_gateway_sqs_role" {
  name = "${var.project_name}-api-gateway-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
# Policy para permitir que o API Gateway envie mensagens para a fila SQS
resource "aws_iam_role_policy" "api_gateway_sqs_policy" {
  name = "${var.project_name}-api-gateway-sqs-policy"
  role = aws_iam_role.api_gateway_sqs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage"
      ]
      Resource = aws_sqs_queue.order_queue.arn
    }]
  })
}
# Integração do método POST com a fila SQS
resource "aws_api_gateway_integration" "sqs_integration" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_orders.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.order_queue.name}"

  credentials = aws_iam_role.api_gateway_sqs_role.arn

  # Parâmetros de requisição para garantir que o Content-Type seja application/x-www-form-urlencoded
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }
  # Template para transformar o corpo da requisição JSON em formato de query string para o SQS
  request_templates = {
    "application/json" = <<EOF
Action=SendMessage&MessageBody=$input.body
EOF
  }

  # Configuração para lidar com respostas do SQS
  passthrough_behavior = "WHEN_NO_MATCH"
}
# Deploy da API Gateway
data "aws_caller_identity" "current" {}

# Deployment da API Gateway
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_orders.http_method
  status_code = "200"
}
# Deployment da API Gateway
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.orders_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.post_orders.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  depends_on = [
    aws_api_gateway_integration.sqs_integration
  ]
}
# Deployment da API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.sqs_integration,
    aws_api_gateway_integration_response.integration_response
  ]

  rest_api_id = aws_api_gateway_rest_api.orders_api.id

  # Força o redeploy sempre que houver mudanças nos recursos, métodos ou integrações
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.orders.id,
      aws_api_gateway_method.post_orders.id,
      aws_api_gateway_integration.sqs_integration.id
    ]))
  }
  
}
# Stage para a API Gateway
resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.orders_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "dev"
}
