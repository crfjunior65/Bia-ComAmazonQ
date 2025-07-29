#ws_security_group" "bia-dev"
output "sg_bia_dev" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.bia-dev.id
}

output "sg_bia_dev_mssql" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.bia-dev-mssql.id
}

#aws_security_group" "mssql-db
output "sg_mssql_db" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.mssql-db.id
}

#ws_security_group" "bia-web"
output "sg_bia_web" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.bia-web.id
}

#ws_security_group" "bia-db"
output "sg_bia_db" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.bia-db.id
}

#ws_security_group" "bia-db"
output "sg_bia_ec2" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.bia-ec2.id
}

#ws_security_group" "bia-db"
output "sg_bia_alb" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.bia-alb.id
}

output "sg_windows" {
  description = "SG Acesso a RDP"
  value       = aws_security_group.windows_sg.id
}

/*
output "sg_acesso_alb" {
  value = aws_iam_role_policy_attachment.ssm_managed_policy.id
}

output "sg_efs_id" {
  description = "SG EFS id"
  value       = aws_security_group.efs_sg.id
}
#aws_security_group" "acesso-ecs
output "sg_ecs_id" {
  description = "SG ECS id"
  value       = aws_security_group.acesso-ecs.id
}

#aws_security_group.acesso-rds.id
output "sg_rds_id" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.acesso-rds.id
}

output "sg_alb_id" {
  value = aws_security_group.alb.id
}

#aws_security_group" "acesso-alb"
#aws_security_group" "acesso-ssh
output "sg_ssh_id" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.acesso-ssh.id
}

#ws_security_group" "acesso-http"
output "sg_http_id" {
  description = "SG Acesso a Instancia Id"
  value       = aws_security_group.acesso-http.id
}


*/
