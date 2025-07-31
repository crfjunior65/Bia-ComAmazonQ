output "cluster_name" {
  description = "Nome do cluster ECS criado"
  value       = aws_ecs_cluster.bia_cluster.name
}

output "cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.bia_cluster.arn
}

output "task_definition_arn" {
  description = "ARN da Task Definition"
  value       = aws_ecs_task_definition.bia_task.arn
}

output "service_name" {
  description = "Nome do serviço ECS"
  value       = aws_ecs_service.bia_service.name
}

output "security_group_web_id" {
  description = "ID do Security Group Web"
  value       = aws_security_group.bia_web.id
}

output "security_group_db_id" {
  description = "ID do Security Group Database"
  value       = aws_security_group.bia_db.id
}

output "log_group_name" {
  description = "Nome do CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.bia_log_group.name
}

output "account_id" {
  description = "ID da conta AWS"
  value       = data.aws_caller_identity.current.account_id
}

output "ecr_repository_url" {
  description = "URL do repositório ECR (você precisa criar manualmente)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/bia-app"
}
