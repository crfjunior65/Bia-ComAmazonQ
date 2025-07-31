# 📋 Variáveis Padronizadas para Todos os Módulos Terraform

# ============================================================================
# VARIÁVEIS GLOBAIS (usar em todos os módulos)
# ============================================================================

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "bia"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name deve conter apenas letras minúsculas, números e hífens."
  }
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "common_tags" {
  description = "Tags comuns para todos os recursos"
  type        = map(string)
  default = {
    Terraform   = "true"
    ManagedBy   = "terraform"
    Project     = "bia"
  }
}

# ============================================================================
# VARIÁVEIS DE REDE (módulo 1-VPC)
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.12.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR deve ser um bloco CIDR válido."
  }
}

variable "public_subnets" {
  description = "CIDRs das subnets públicas"
  type        = list(string)
  default     = ["10.12.101.0/24", "10.12.102.0/24"]
}

variable "private_subnets" {
  description = "CIDRs das subnets privadas"
  type        = list(string)
  default     = ["10.12.201.0/24", "10.12.202.0/24"]
}

variable "database_subnets" {
  description = "CIDRs das subnets de banco de dados"
  type        = list(string)
  default     = ["10.12.21.0/24", "10.12.22.0/24"]
}

variable "availability_zones" {
  description = "Zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ============================================================================
# VARIÁVEIS DE BANCO DE DADOS (módulo 3-RDS)
# ============================================================================

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
  
  validation {
    condition     = can(regex("^db\\.", var.db_instance_class))
    error_message = "DB instance class deve começar com 'db.'."
  }
}

variable "db_allocated_storage" {
  description = "Armazenamento alocado para RDS (GB)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "DB allocated storage deve estar entre 20 e 1000 GB."
  }
}

variable "db_max_allocated_storage" {
  description = "Armazenamento máximo para auto scaling (GB)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "bia"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "DB name deve começar com letra e conter apenas letras, números e underscores."
  }
}

variable "db_username" {
  description = "Nome do usuário master do banco"
  type        = string
  default     = "postgres"
  
  validation {
    condition     = length(var.db_username) >= 1 && length(var.db_username) <= 63
    error_message = "DB username deve ter entre 1 e 63 caracteres."
  }
}

variable "db_backup_retention_period" {
  description = "Período de retenção de backup (dias)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.db_backup_retention_period >= 0 && var.db_backup_retention_period <= 35
    error_message = "Backup retention period deve estar entre 0 e 35 dias."
  }
}

# ============================================================================
# VARIÁVEIS DE ECS (módulo 6-ECS)
# ============================================================================

variable "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  type        = string
  default     = null  # Será gerado automaticamente se não fornecido
}

variable "task_cpu" {
  description = "CPU para a task definition (em unidades de CPU)"
  type        = number
  default     = 1024
  
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU deve ser: 256, 512, 1024, 2048 ou 4096."
  }
}

variable "task_memory" {
  description = "Memória para a task definition (MB)"
  type        = number
  default     = 2048
  
  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Task memory deve estar entre 512 MB e 30720 MB."
  }
}

variable "desired_count" {
  description = "Número desejado de tasks rodando"
  type        = number
  default     = 2
  
  validation {
    condition     = var.desired_count >= 1 && var.desired_count <= 10
    error_message = "Desired count deve estar entre 1 e 10."
  }
}

variable "container_port" {
  description = "Porta do container da aplicação"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port deve estar entre 1 e 65535."
  }
}

variable "image_tag" {
  description = "Tag da imagem Docker"
  type        = string
  default     = "latest"
}

# ============================================================================
# VARIÁVEIS DE ALB (módulo 5-ALB)
# ============================================================================

variable "alb_internal" {
  description = "Se o ALB deve ser interno"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Caminho para health check"
  type        = string
  default     = "/api/versao"
}

variable "health_check_interval" {
  description = "Intervalo do health check (segundos)"
  type        = number
  default     = 30
  
  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "Health check interval deve estar entre 5 e 300 segundos."
  }
}

variable "health_check_timeout" {
  description = "Timeout do health check (segundos)"
  type        = number
  default     = 5
  
  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "Health check timeout deve estar entre 2 e 120 segundos."
  }
}

# ============================================================================
# VARIÁVEIS DE SEGURANÇA
# ============================================================================

variable "allowed_cidr_blocks" {
  description = "Blocos CIDR permitidos para acesso SSH (desenvolvimento)"
  type        = list(string)
  default     = []  # Deve ser preenchido com IPs específicos
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "Todos os CIDR blocks devem ser válidos."
  }
}

variable "enable_deletion_protection" {
  description = "Habilitar proteção contra exclusão"
  type        = bool
  default     = false  # true para produção
}

# ============================================================================
# VARIÁVEIS DE MONITORAMENTO
# ============================================================================

variable "enable_detailed_monitoring" {
  description = "Habilitar monitoramento detalhado"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs no CloudWatch"
  type        = number
  default     = 7
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days deve ser um valor válido do CloudWatch."
  }
}

# ============================================================================
# OUTPUTS PADRONIZADOS (usar em todos os módulos)
# ============================================================================

# Exemplo de outputs que cada módulo deve ter:

# output "module_name" {
#   description = "Nome do módulo"
#   value       = "nome-do-modulo"
# }

# output "resources_created" {
#   description = "Lista de recursos criados"
#   value       = [
#     # Lista dos recursos principais criados
#   ]
# }

# output "resource_arns" {
#   description = "ARNs dos recursos principais"
#   value = {
#     # Mapa com ARNs dos recursos
#   }
# }

# ============================================================================
# LOCALS PADRONIZADOS (usar em todos os módulos)
# ============================================================================

# locals {
#   # Nome padrão para recursos
#   name_prefix = "${var.project_name}-${var.environment}"
#   
#   # Tags padrão
#   default_tags = merge(var.common_tags, {
#     Environment = var.environment
#     Project     = var.project_name
#   })
#   
#   # Account ID e região atual
#   account_id = data.aws_caller_identity.current.account_id
#   region     = data.aws_region.current.name
# }

# ============================================================================
# DATA SOURCES PADRONIZADOS (usar em todos os módulos)
# ============================================================================

# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}
# data "aws_availability_zones" "available" {
#   state = "available"
# }

# ============================================================================
# EXEMPLO DE TERRAFORM.TFVARS PARA DESENVOLVIMENTO
# ============================================================================

# project_name = "bia"
# environment  = "dev"
# aws_region   = "us-east-1"
# 
# # VPC
# vpc_cidr = "10.12.0.0/16"
# 
# # RDS
# db_instance_class = "db.t3.micro"
# db_allocated_storage = 20
# 
# # ECS
# task_cpu = 1024
# task_memory = 2048
# desired_count = 1
# 
# # Segurança (SUBSTITUA PELO SEU IP)
# allowed_cidr_blocks = ["SEU_IP_PUBLICO/32"]
# 
# # Monitoramento
# log_retention_days = 7

# ============================================================================
# EXEMPLO DE TERRAFORM.TFVARS PARA PRODUÇÃO
# ============================================================================

# project_name = "bia"
# environment  = "prod"
# aws_region   = "us-east-1"
# 
# # VPC
# vpc_cidr = "10.12.0.0/16"
# 
# # RDS
# db_instance_class = "db.t3.small"
# db_allocated_storage = 100
# db_backup_retention_period = 30
# 
# # ECS
# task_cpu = 2048
# task_memory = 4096
# desired_count = 3
# 
# # Segurança
# enable_deletion_protection = true
# 
# # Monitoramento
# log_retention_days = 30
# enable_detailed_monitoring = true
