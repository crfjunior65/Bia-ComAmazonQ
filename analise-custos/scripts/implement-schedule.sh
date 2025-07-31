#!/bin/bash

# Script para Implementar Schedule de Economia
# Economia estimada: $5.06/mês (desligar 16h/dia)

echo "⏰ Implementando schedule para economia de custos..."

# 1. Criar função Lambda para gerenciar ECS
echo "🔧 Criando função Lambda para gerenciar ECS..."

# Criar arquivo da função Lambda
cat > /tmp/ecs-scheduler.py << 'EOF'
import boto3
import json
import os

def lambda_handler(event, context):
    ecs = boto3.client('ecs')
    cluster_name = os.environ['CLUSTER_NAME']
    service_name = os.environ['SERVICE_NAME']
    
    action = event.get('action', 'stop')
    
    try:
        if action == 'stop':
            # Parar o serviço (desired count = 0)
            response = ecs.update_service(
                cluster=cluster_name,
                service=service_name,
                desiredCount=0
            )
            message = f"Serviço {service_name} parado com sucesso"
            
        elif action == 'start':
            # Iniciar o serviço (desired count = 1)
            response = ecs.update_service(
                cluster=cluster_name,
                service=service_name,
                desiredCount=1
            )
            message = f"Serviço {service_name} iniciado com sucesso"
            
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': message,
                'response': response
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
EOF

# Criar ZIP da função
cd /tmp
zip ecs-scheduler.zip ecs-scheduler.py

# 2. Criar role IAM para a função Lambda
echo "🔐 Criando role IAM para Lambda..."

cat > /tmp/lambda-trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

cat > /tmp/lambda-ecs-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:DescribeServices"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# Criar role
aws iam create-role \
    --role-name bia-ecs-scheduler-role \
    --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
    --region us-east-1

# Anexar policy
aws iam put-role-policy \
    --role-name bia-ecs-scheduler-role \
    --policy-name bia-ecs-scheduler-policy \
    --policy-document file:///tmp/lambda-ecs-policy.json \
    --region us-east-1

# Aguardar propagação da role
sleep 10

# 3. Criar função Lambda
echo "⚡ Criando função Lambda..."

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws lambda create-function \
    --function-name bia-ecs-scheduler \
    --runtime python3.9 \
    --role arn:aws:iam::${ACCOUNT_ID}:role/bia-ecs-scheduler-role \
    --handler ecs-scheduler.lambda_handler \
    --zip-file fileb:///tmp/ecs-scheduler.zip \
    --environment Variables='{CLUSTER_NAME=custer-bia,SERVICE_NAME=service-bia}' \
    --region us-east-1

# 4. Criar regras do EventBridge para schedule
echo "📅 Criando regras de schedule..."

# Regra para parar às 18:00 (horário de Brasília = 21:00 UTC)
aws events put-rule \
    --name bia-stop-schedule \
    --schedule-expression "cron(0 21 * * MON-FRI *)" \
    --description "Para o serviço BIA às 18:00 (segunda a sexta)" \
    --region us-east-1

# Regra para iniciar às 08:00 (horário de Brasília = 11:00 UTC)
aws events put-rule \
    --name bia-start-schedule \
    --schedule-expression "cron(0 11 * * MON-FRI *)" \
    --description "Inicia o serviço BIA às 08:00 (segunda a sexta)" \
    --region us-east-1

# 5. Adicionar targets às regras
echo "🎯 Configurando targets das regras..."

# Target para parar
aws events put-targets \
    --rule bia-stop-schedule \
    --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:bia-ecs-scheduler","Input"='{"action":"stop"}' \
    --region us-east-1

# Target para iniciar
aws events put-targets \
    --rule bia-start-schedule \
    --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:bia-ecs-scheduler","Input"='{"action":"start"}' \
    --region us-east-1

# 6. Dar permissão ao EventBridge para invocar a Lambda
echo "🔑 Configurando permissões..."

aws lambda add-permission \
    --function-name bia-ecs-scheduler \
    --statement-id allow-eventbridge-stop \
    --action lambda:InvokeFunction \
    --principal events.amazonaws.com \
    --source-arn arn:aws:events:us-east-1:${ACCOUNT_ID}:rule/bia-stop-schedule \
    --region us-east-1

aws lambda add-permission \
    --function-name bia-ecs-scheduler \
    --statement-id allow-eventbridge-start \
    --action lambda:InvokeFunction \
    --principal events.amazonaws.com \
    --source-arn arn:aws:events:us-east-1:${ACCOUNT_ID}:rule/bia-start-schedule \
    --region us-east-1

# 7. Criar script para controle manual
cat > /tmp/manual-ecs-control.sh << 'EOF'
#!/bin/bash
# Controle manual do serviço ECS

case "$1" in
    start)
        echo "🚀 Iniciando serviço BIA..."
        aws lambda invoke \
            --function-name bia-ecs-scheduler \
            --payload '{"action":"start"}' \
            --region us-east-1 \
            /tmp/lambda-response.json
        cat /tmp/lambda-response.json
        ;;
    stop)
        echo "⏹️  Parando serviço BIA..."
        aws lambda invoke \
            --function-name bia-ecs-scheduler \
            --payload '{"action":"stop"}' \
            --region us-east-1 \
            /tmp/lambda-response.json
        cat /tmp/lambda-response.json
        ;;
    status)
        echo "📊 Status do serviço BIA..."
        aws ecs describe-services \
            --cluster custer-bia \
            --services service-bia \
            --region us-east-1 \
            --query 'services[0].[serviceName,desiredCount,runningCount,status]' \
            --output table
        ;;
    *)
        echo "Uso: $0 {start|stop|status}"
        echo "  start  - Inicia o serviço"
        echo "  stop   - Para o serviço"
        echo "  status - Mostra status atual"
        ;;
esac
EOF

chmod +x /tmp/manual-ecs-control.sh

echo "✅ Schedule implementado com sucesso!"
echo ""
echo "📋 Resumo da configuração:"
echo "  • Serviço para automaticamente às 18:00 (seg-sex)"
echo "  • Serviço inicia automaticamente às 08:00 (seg-sex)"
echo "  • Economia: ~$5.06/mês (16h/dia parado)"
echo ""
echo "🎮 Controle manual:"
echo "  /tmp/manual-ecs-control.sh start   # Iniciar manualmente"
echo "  /tmp/manual-ecs-control.sh stop    # Parar manualmente"
echo "  /tmp/manual-ecs-control.sh status  # Ver status"
echo ""
echo "⚠️  IMPORTANTE: Use apenas em ambiente de desenvolvimento!"
