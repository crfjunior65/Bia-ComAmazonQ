# 🐳 Configuração Corrigida do ECS - Task Definition Segura

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key    = "vpc/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "sg" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key    = "security-groups/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key    = "rds/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state-${var.environment}-${data.aws_caller_identity.current.account_id}"
    key    = "alb/terraform.tfstate"
    region = var.aws_region
  }
}

# ============================================================================
# LOCALS
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  default_tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = var.project_name
    Module      = "ecs"
  })
  
  # ECR Repository URI
  ecr_repository_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.project_name}"
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-logs"
  })
}

# ============================================================================
# IAM ROLES PARA ECS
# ============================================================================

# Task Execution Role (para ECS Agent)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-ecs-task-execution-role"
  })
}

# Anexar política padrão para Task Execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Política adicional para Secrets Manager
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${local.name_prefix}-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          data.terraform_remote_state.rds.outputs.db_credentials_secret_arn
        ]
      }
    ]
  })
}

# Task Role (para a aplicação)
resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-ecs-task-role"
  })
}

# Política para a aplicação acessar outros serviços AWS se necessário
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${local.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.app.arn}:*"
      }
    ]
  })
}

# ============================================================================
# ECS CLUSTER
# ============================================================================

resource "aws_ecs_cluster" "main" {
  name = local.name_prefix

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.app.name
      }
    }
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-cluster"
  })
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ============================================================================
# ECS TASK DEFINITION (CORRIGIDA)
# ============================================================================

resource "aws_ecs_task_definition" "app" {
  family                   = local.name_prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-container"
      image = "${local.ecr_repository_uri}:${var.image_tag}"
      
      cpu       = var.task_cpu
      memory    = var.task_memory
      essential = true
      
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
          name          = "http"
        }
      ]
      
      # ✅ USAR SECRETS MANAGER (NÃO HARDCODED)
      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "${data.terraform_remote_state.rds.outputs.db_credentials_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${data.terraform_remote_state.rds.outputs.db_credentials_secret_arn}:password::"
        }
      ]
      
      # ✅ VARIÁVEIS DE AMBIENTE SEGURAS
      environment = [
        {
          name  = "DB_HOST"
          value = data.terraform_remote_state.rds.outputs.db_endpoint
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = data.terraform_remote_state.rds.outputs.db_name
        },
        {
          name  = "NODE_ENV"
          value = var.environment == "prod" ? "production" : "development"
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        }
      ]
      
      # ✅ CONFIGURAÇÃO DE LOGS
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      # ✅ HEALTH CHECK
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"
        ]
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = 3
        startPeriod = 60
      }
      
      # ✅ CONFIGURAÇÕES DE SEGURANÇA
      readonlyRootFilesystem = false  # Pode ser true se a app não precisar escrever no filesystem
      
      # ✅ CONFIGURAÇÕES DE RECURSOS
      ulimits = [
        {
          name      = "nofile"
          softLimit = 65536
          hardLimit = 65536
        }
      ]
    }
  ])

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-task-definition"
  })
}

# ============================================================================
# ECS SERVICE (CORRIGIDO)
# ============================================================================

resource "aws_ecs_service" "app" {
  name            = local.name_prefix
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  # ✅ CONFIGURAÇÃO DE REDE SEGURA (SUBNETS PRIVADAS)
  network_configuration {
    security_groups  = [data.terraform_remote_state.sg.outputs.ecs_security_group_id]
    subnets         = data.terraform_remote_state.vpc.outputs.private_subnets
    assign_public_ip = false  # ✅ Sem IP público
  }
  
  # ✅ CONFIGURAÇÃO DO LOAD BALANCER
  load_balancer {
    target_group_arn = data.terraform_remote_state.alb.outputs.target_group_arn
    container_name   = "${var.project_name}-container"
    container_port   = var.container_port
  }
  
  # ✅ CONFIGURAÇÃO DE DEPLOYMENT
  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
    
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }
  
  # ✅ SERVICE DISCOVERY (OPCIONAL)
  # service_registries {
  #   registry_arn = aws_service_discovery_service.app.arn
  # }
  
  # ✅ ENABLE EXECUTE COMMAND (para debugging)
  enable_execute_command = var.environment == "dev" ? true : false
  
  # ✅ DEPENDÊNCIAS
  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    data.terraform_remote_state.alb
  ]

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-service"
  })
}

# ============================================================================
# AUTO SCALING (OPCIONAL)
# ============================================================================

resource "aws_appautoscaling_target" "ecs_target" {
  count = var.environment == "prod" ? 1 : 0
  
  max_capacity       = var.desired_count * 3
  min_capacity       = var.desired_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count = var.environment == "prod" ? 1 : 0
  
  name               = "${local.name_prefix}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.main.arn
}

output "service_name" {
  description = "Nome do serviço ECS"
  value       = aws_ecs_service.app.name
}

output "service_arn" {
  description = "ARN do serviço ECS"
  value       = aws_ecs_service.app.id
}

output "task_definition_arn" {
  description = "ARN da task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "log_group_name" {
  description = "Nome do CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.app.name
}

output "task_execution_role_arn" {
  description = "ARN da role de execução da task"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  description = "ARN da role da task"
  value       = aws_iam_role.ecs_task_role.arn
}

# ============================================================================
# PRINCIPAIS CORREÇÕES IMPLEMENTADAS
# ============================================================================

# ✅ 1. SEGURANÇA:
#    - Credenciais via Secrets Manager (não hardcoded)
#    - Subnets privadas (não públicas)
#    - IAM roles com menor privilégio
#    - Sem IP público para containers

# ✅ 2. CONFIGURAÇÃO:
#    - ECR URI dinâmico (não hardcoded)
#    - Variáveis de ambiente configuráveis
#    - Health checks implementados
#    - Logs centralizados no CloudWatch

# ✅ 3. ALTA DISPONIBILIDADE:
#    - Fargate para gerenciamento automático
#    - Auto scaling configurado (produção)
#    - Deployment circuit breaker
#    - Rolling deployments

# ✅ 4. MONITORAMENTO:
#    - CloudWatch Logs configurado
#    - Health checks com retry
#    - Execute command para debugging
#    - Métricas de CPU para scaling

# ✅ 5. BOAS PRÁTICAS:
#    - Tags padronizadas
#    - Outputs documentados
#    - Dependências explícitas
#    - Configuração por ambiente
