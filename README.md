# aws-microservices-order-processing
Arquitetura simples de microsserviço no ambiente AWS para processamento de pagamento de uma compra

Estrutura dos arquivos:
```
aws-microservices-order-processing/
│
├── infra/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── sqs.tf
│   ├── lambda.tf
│   ├── api_gateway.tf
│   ├── dynamodb.tf
│   ├── step_functions.tf
│   └── sns.tf
│
├── lambdas/
│   ├── enqueue_order/
│   │   └── handler.py
│   ├── process_queue/
│   │   └── handler.py
│   ├── process_payment/
│   │   └── handler.py
│   └── update_order/
│       └── handler.py
│
├── statemachine/
│   └── order_workflow.asl.json
│
├── docs/
│   ├── architecture.png
│   └── decisions.md
│
└── README.md
