# Sistema Genérico de Importação de Recursos AWS

Este sistema permite verificar automaticamente se recursos AWS já existem e importá-los para o estado do Terraform antes do deploy, evitando erros de "EntityAlreadyExists".

## Como Funciona

1. **Script `check-and-import.sh`**: Verifica cada recurso listado em `resources.conf`
2. **Arquivo `resources.conf`**: Contém a lista de recursos a serem verificados
3. **GitHub Actions**: Executa o script automaticamente durante o deploy

## Adicionando Novos Recursos

### 1. Edite `resources.conf`

Adicione uma nova linha no array `RESOURCES`:

```bash
"aws_dynamodb_table|my_table|my-table-name|check_dynamodb_table"
```

### 2. Adicione Função de Verificação (se necessário)

Se o tipo de recurso não existir no script, adicione uma função de verificação em `check-and-import.sh`:

```bash
check_dynamodb_table() {
    local table_name=$1
    if aws dynamodb describe-table --table-name "$table_name" 2>/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}
```

### 3. Adicione Caso no Switch

Adicione o caso correspondente na seção de construção do ID AWS:

```bash
aws_dynamodb_table)
    aws_id="$aws_name"
    ;;
```

## Recursos Suportados

- ✅ `aws_iam_role` - IAM Roles
- ✅ `aws_iam_policy` - IAM Policies
- ✅ `aws_sqs_queue` - SQS Queues
- ✅ `aws_lambda_function` - Lambda Functions
- ✅ `aws_dynamodb_table` - DynamoDB Tables
- ✅ `aws_s3_bucket` - S3 Buckets
- ✅ `aws_cloudwatch_log_group` - CloudWatch Log Groups

## Exemplo de Uso

Para adicionar uma tabela DynamoDB:

1. No Terraform:
```hcl
resource "aws_dynamodb_table" "my_table" {
  name = "my-table-name"
  # ... outras configurações
}
```

2. No `resources.conf`:
```bash
"aws_dynamodb_table|my_table|my-table-name|check_dynamodb_table"
```

3. O sistema irá automaticamente:
   - Verificar se a tabela existe
   - Importá-la se existir
   - Criá-la se não existir

## Executando Manualmente

```bash
cd infra
./check-and-import.sh
```

## Logs

O script fornece logs detalhados:
- 🔍 Verificando recursos existentes
- 📦 Recurso encontrado, importando
- 🆕 Recurso não existe, será criado
- ✅ Importação bem-sucedida
- ❌ Falha na importação