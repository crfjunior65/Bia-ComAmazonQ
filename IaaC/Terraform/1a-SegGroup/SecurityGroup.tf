
resource "aws_security_group" "bia-dev" {
  name        = "bia-dev"
  description = "bia-dev"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Acesso_HTTP Porta 3001"
  }

}

resource "aws_security_group" "bia-dev-mssql" {
  name        = "bia-dev-mssql"
  description = "bia-dev-mssql"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  #ingress {
  #  from_port   = 1433
  #  to_port     = 1433
  #  protocol    = "TCP"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Acesso_MS_SQL Porta 1433"
  }

}

resource "aws_security_group" "bia-web" {
  name        = "bia-web"
  description = "bia-web"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Acesso_HTTP Porta 80 e 443"
  }

}

resource "aws_security_group" "bia-build" {
  name        = "bia-build"
  description = "bia-build"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Acesso_Build"
  }
}

resource "aws_security_group" "bia-db" {
  name        = "bia-db"
  description = "bia-db"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "TCP"
    security_groups = [
      aws_security_group.bia-web.id,
      aws_security_group.bia-ec2.id,
      aws_security_group.bia-dev-mssql.id,
      aws_security_group.bia-build.id,
      aws_security_group.bia-dev.id
    ]
  }

  ingress {
    from_port = 1433
    to_port   = 1433
    protocol  = "TCP"
    security_groups = [
      #aws_security_group.bia-web.id,
      #aws_security_group.bia-ec2.id,
      aws_security_group.bia-dev.id,
      aws_security_group.bia-dev-mssql.id
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Acesso_RDS"
  }

}

resource "aws_security_group" "mssql-db" {
  name        = "mssql-db"
  description = "mssql-db"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  ingress {
    from_port = 1433
    to_port   = 1433
    protocol  = "TCP"
    security_groups = [
      #aws_security_group.bia-web.id,
      #aws_security_group.bia-ec2.id,
      aws_security_group.bia-dev.id,
      aws_security_group.bia-dev-mssql.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Acesso_PostGres Porta 1433"
  }

}

resource "aws_security_group" "bia-alb" {
  name        = "bia-alb"
  description = "bia-alb"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
    #security_groups = [
    #  aws_security_group.bia-web.id,
    #  aws_security_group.bia-dev.id
    #]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    #security_groups = [
    #  aws_security_group.bia-web.id,
    #  aws_security_group.bia-dev.id
    #]
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Acesso_ALB Porta 80 e 443"
  }

}

resource "aws_security_group" "bia-ec2" {
  name        = "bia-ec2"
  description = "bia-ec2"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "TCP"
    security_groups = [
      aws_security_group.bia-alb.id
    ]
    #cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Acesso_ECS - EC2"
  }

}

# Cria um security group para permitir RDP e HTTP/HTTPS
resource "aws_security_group" "windows_sg" {
  name        = "windows-sg"
  description = "Permite RDP, HTTP e HTTPS"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_vpc_id

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    security_groups = [
      aws_security_group.bia-dev.id
    ]

    #cidr_blocks = ["0.0.0.0/0"] # Restrinja isso para seu IP em produção!
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
