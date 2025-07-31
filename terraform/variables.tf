variable "aws_region" {
  description = "Região AWS para deploy"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instância EC2 para o cluster ECS"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Nome do Key Pair para acesso SSH às instâncias"
  type        = string
}

variable "db_host" {
  description = "Endpoint do banco de dados RDS"
  type        = string
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_user" {
  description = "Usuário do banco de dados"
  type        = string
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}
