#!/bin/bash

# Script genérico para verificar e importar recursos AWS existentes
# Uso: ./check-and-import.sh <terraform_dir>

set -e

TERRAFORM_DIR=${1:-"."}
cd "$TERRAFORM_DIR"

# Função para verificar se IAM role existe
check_iam_role() {
    local role_name=$1
    if aws iam get-role --role-name "$role_name" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Função para verificar se SQS queue existe
check_sqs_queue() {
    local queue_name=$1
    if aws sqs get-queue-url --queue-name "$queue_name" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Função para verificar se Lambda function existe
check_lambda_function() {
    local function_name=$1
    if aws lambda get-function --function-name "$function_name" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Função para verificar se IAM policy existe
check_iam_policy() {
    local policy_name=$1
    if aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$policy_name" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Função para verificar se DynamoDB table existe
check_dynamodb_table() {
    local table_name=$1
    if aws dynamodb describe-table --table-name "$table_name" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Função para verificar se S3 bucket existe
check_s3_bucket() {
    local bucket_name=$1
    if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Função para verificar se CloudWatch Log Group existe
check_cloudwatch_log_group() {
    local log_group_name=$1
    if aws logs describe-log-groups --log-group-name-prefix "$log_group_name" --query 'logGroups[?logGroupName==`'$log_group_name'`]' --output text | grep -q "$log_group_name"; then
        echo "true"
    else
        echo "false"
    fi
}

# Função para importar recurso
import_resource() {
    local resource_type=$1
    local resource_name=$2
    local aws_resource_id=$3

    echo "Importing $resource_type.$resource_name from $aws_resource_id"
    if terraform import "$resource_type.$resource_name" "$aws_resource_id"; then
        echo "✅ Successfully imported $resource_type.$resource_name"
    else
        echo "❌ Failed to import $resource_type.$resource_name"
        return 1
    fi
}

# Lista de recursos para verificar (carregada do arquivo de configuração)
if [ -f "resources.conf" ]; then
    source resources.conf
else
    echo "❌ Arquivo resources.conf não encontrado!"
    exit 1
fi

echo "🔍 Checking for existing AWS resources..."

# Para cada recurso, verificar se existe e importar se necessário
for resource in "${RESOURCES[@]}"; do
    IFS='|' read -r tf_type tf_name aws_name check_func <<< "$resource"

    echo "Checking $tf_type.$tf_name ($aws_name)..."

    # Chamar função de verificação
    if exists=$($check_func "$aws_name"); then
        if [ "$exists" = "true" ]; then
            echo "📦 Resource $aws_name exists, importing..."

            # Construir o ID do recurso AWS baseado no tipo
            case $tf_type in
                aws_iam_role)
                    aws_id="$aws_name"
                    ;;
                aws_iam_policy)
                    account_id=$(aws sts get-caller-identity --query Account --output text)
                    aws_id="arn:aws:iam::$account_id:policy/$aws_name"
                    ;;
                aws_sqs_queue)
                    account_id=$(aws sts get-caller-identity --query Account --output text)
                    region=$(aws configure get region)
                    aws_id="https://sqs.$region.amazonaws.com/$account_id/$aws_name"
                    ;;
                aws_lambda_function)
                    aws_id="$aws_name"
                    ;;
                aws_dynamodb_table)
                    aws_id="$aws_name"
                    ;;
                aws_s3_bucket)
                    aws_id="$aws_name"
                    ;;
                aws_cloudwatch_log_group)
                    aws_id="$aws_name"
                    ;;
                *)
                    echo "⚠️  Unknown resource type: $tf_type, skipping..."
                    echo "💡 Supported types: aws_iam_role, aws_iam_policy, aws_sqs_queue, aws_lambda_function, aws_dynamodb_table, aws_s3_bucket, aws_cloudwatch_log_group"
                    continue
                    ;;
            esac

            # Importar o recurso
            if import_resource "$tf_type" "$tf_name" "$aws_id"; then
                echo "✅ $tf_type.$tf_name imported successfully"
            else
                echo "❌ Failed to import $tf_type.$tf_name"
            fi
        else
            echo "🆕 Resource $aws_name does not exist, will be created by Terraform"
        fi
    else
        echo "❌ Error checking $aws_name"
    fi
done

echo "🎉 Resource check and import completed!"