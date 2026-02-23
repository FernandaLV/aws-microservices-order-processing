"""
Lambda acionada pelo SQS.
O SQS envia um batch de registros no campo 'Records'.
"""

import json

def lambda_handler(event, context): # pylint: disable=unused-argument

    print("Evento recebido:")
    print(json.dumps(event, indent=2))

    # Percorre cada mensagem recebida da fila
    for record in event["Records"]:
        body = record["body"]

        print("Mensagem recebida da fila:")
        print(body)

    return {
        "statusCode": 200,
        "body": "Mensagens processadas com sucesso"
    }
