#!/bin/bash

# 🚀 Script de Implementação Rápida - Otimizações de Custo BIA
# Economia estimada: $4.15/mês (18.2% de redução)

set -e  # Parar em caso de erro

echo "💰 Iniciando otimizações de custo do projeto BIA..."
echo "📅 Data: $(date)"
echo "🎯 Economia estimada: \$4.15/mês (18.2% de redução)"
echo ""

# Verificar pré-requisitos
echo "🔍 Verificando pré-requisitos..."

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI não encontrado. Instale o AWS CLI primeiro."
    exit 1
fi

# Verificar credenciais AWS
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Credenciais AWS não configuradas. Configure com 'aws configure'."
    exit 1
fi

# Verificar região
REGION=$(aws configure get region)
if [ "$REGION" != "us-east-1" ]; then
    echo "⚠️  Região configurada: $REGION (esperado: us-east-1)"
    echo "Continuando mesmo assim..."
fi

echo "✅ Pré-requisitos verificados!"
echo ""

# Função para log com timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Função para verificar sucesso
check_success() {
    if [ $? -eq 0 ]; then
        log "✅ $1 - Sucesso"
    else
        log "❌ $1 - Falhou"
        return 1
    fi
}

# Menu de opções
echo "📋 Selecione as otimizações para implementar:"
echo ""
echo "1) 🐳 ECR Lifecycle Policy (Economia: \$0.03-0.10/mês, Downtime: 0)"
echo "2) 📊 CloudWatch Log Optimization (Economia: \$0.10-0.20/mês, Downtime: 0)"
echo "3) 🗄️  RDS GP2→GP3 Migration (Economia: \$0.30/mês, Downtime: 5-10min)"
echo "4) ⚡ Spot Instances (Economia: \$3.79/mês, Risco: Interrupção)"
echo "5) ⏰ Schedule Automático (Economia: \$10.80/mês, Apenas DEV)"
echo "6) 🚀 Implementar TODAS as otimizações básicas (1+2)"
echo "7) 💪 Implementar TODAS as otimizações (1+2+3+4)"
echo "0) ❌ Sair"
echo ""

read -p "Digite sua opção (0-7): " opcao

case $opcao in
    1)
        log "🐳 Implementando ECR Lifecycle Policy..."
        cd scripts
        chmod +x optimize-ecr.sh
        ./optimize-ecr.sh
        check_success "ECR Optimization"
        ;;
    2)
        log "📊 Implementando CloudWatch Optimization..."
        cd scripts
        chmod +x optimize-cloudwatch.sh
        ./optimize-cloudwatch.sh
        check_success "CloudWatch Optimization"
        ;;
    3)
        log "🗄️  Implementando RDS GP2→GP3 Migration..."
        cd scripts
        chmod +x optimize-rds.sh
        ./optimize-rds.sh
        log "⚠️  Para completar a migração, execute: /tmp/migrate-rds-to-gp3.sh"
        log "⚠️  ATENÇÃO: Isso causará 5-10 minutos de downtime!"
        ;;
    4)
        log "⚡ Implementando Spot Instances..."
        if command -v terraform &> /dev/null; then
            cd terraform
            terraform plan -target=aws_launch_template.ecs_spot_template
            read -p "Aplicar mudanças? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                terraform apply -target=aws_launch_template.ecs_spot_template
                check_success "Spot Instances Implementation"
            else
                log "⏭️  Spot Instances - Cancelado pelo usuário"
            fi
        else
            log "❌ Terraform não encontrado. Instale o Terraform primeiro."
        fi
        ;;
    5)
        log "⏰ Implementando Schedule Automático..."
        cd scripts
        chmod +x implement-schedule.sh
        echo "⚠️  ATENÇÃO: Use apenas em ambiente de desenvolvimento!"
        read -p "Confirma implementação do schedule? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            ./implement-schedule.sh
            check_success "Schedule Implementation"
        else
            log "⏭️  Schedule - Cancelado pelo usuário"
        fi
        ;;
    6)
        log "🚀 Implementando otimizações básicas (ECR + CloudWatch)..."
        cd scripts
        chmod +x optimize-*.sh
        
        log "🐳 Executando ECR optimization..."
        ./optimize-ecr.sh
        check_success "ECR Optimization"
        
        log "📊 Executando CloudWatch optimization..."
        ./optimize-cloudwatch.sh
        check_success "CloudWatch Optimization"
        
        log "✅ Otimizações básicas concluídas!"
        log "💰 Economia estimada: \$0.13-0.30/mês"
        ;;
    7)
        log "💪 Implementando TODAS as otimizações..."
        cd scripts
        chmod +x optimize-*.sh
        
        # ECR
        log "🐳 Executando ECR optimization..."
        ./optimize-ecr.sh
        check_success "ECR Optimization"
        
        # CloudWatch
        log "📊 Executando CloudWatch optimization..."
        ./optimize-cloudwatch.sh
        check_success "CloudWatch Optimization"
        
        # RDS
        log "🗄️  Executando RDS analysis..."
        ./optimize-rds.sh
        log "⚠️  RDS Migration script criado em /tmp/migrate-rds-to-gp3.sh"
        
        # Spot Instances
        if command -v terraform &> /dev/null; then
            log "⚡ Configurando Spot Instances..."
            cd ../terraform
            terraform plan -target=aws_launch_template.ecs_spot_template
            read -p "Aplicar Spot Instances? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                terraform apply -target=aws_launch_template.ecs_spot_template
                check_success "Spot Instances Implementation"
            else
                log "⏭️  Spot Instances - Cancelado pelo usuário"
            fi
        else
            log "⚠️  Terraform não encontrado - Spot Instances não implementado"
        fi
        
        log "✅ Implementação completa!"
        log "💰 Economia estimada: \$4.15/mês (sem RDS migration)"
        log "💰 Economia total possível: \$4.45/mês (com RDS migration)"
        ;;
    0)
        log "👋 Saindo..."
        exit 0
        ;;
    *)
        log "❌ Opção inválida!"
        exit 1
        ;;
esac

echo ""
log "🎉 Implementação concluída!"
echo ""
echo "📊 Próximos passos:"
echo "1. Monitorar custos no AWS Cost Explorer"
echo "2. Verificar funcionamento da aplicação"
echo "3. Configurar alertas de budget"
echo "4. Acompanhar métricas por 30 dias"
echo ""
echo "📚 Documentação completa em: analise-custos/docs/"
echo "🛠️  Scripts adicionais em: analise-custos/scripts/"
echo ""
echo "💡 Para suporte, consulte: analise-custos/docs/README.md"
