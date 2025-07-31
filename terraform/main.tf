# Terraform configuration for BIA project ECS infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Security Groups seguindo as regras do projeto BIA
resource "aws_security_group" "bia_web" {
  name        = "bia-web"
  description = "Security Group para Web do projeto BIA"
  vpc_id      = data.aws_vpc.default.id

  # Porta da aplicação
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "acesso publico HTTP"
  }

  # Portas dinâmicas do ECS
  ingress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "portas dinamicas ECS"
  }

  # SSH para administração
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "bia-web"
    Project = "BIA"
  }
}

resource "aws_security_group" "bia_db" {
  name        = "bia-db"
  description = "Security Group para Database do projeto BIA"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bia_web.id]
    description     = "acesso vindo de bia-web"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "bia-db"
    Project = "BIA"
  }
}

# IAM Role para instâncias ECS
resource "aws_iam_role" "ecs_instance_role" {
  name = "bia-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "bia-ecs-instance-role"
    Project = "BIA"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "bia-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# IAM Role para execução de tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "bia-ecs-task-execution-role"

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

  tags = {
    Name    = "bia-ecs-task-execution-role"
    Project = "BIA"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Launch Template para instâncias ECS
resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "bia-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.bia_web.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=bia-cluster >> /etc/ecs/ecs.config
    yum update -y
    yum install -y curl
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "bia-ecs-instance"
      Project = "BIA"
    }
  }

  tags = {
    Name    = "bia-ecs-launch-template"
    Project = "BIA"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "bia-ecs-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = []
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "bia-ecs-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Project"
    value               = "BIA"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = false
  }
}

# ECS Cluster seguindo nomenclatura do projeto
resource "aws_ecs_cluster" "bia_cluster" {
  name = "bia-cluster"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = {
    Name    = "bia-cluster"
    Project = "BIA"
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "bia-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = {
    Name    = "bia-capacity-provider"
    Project = "BIA"
  }
}

resource "aws_ecs_cluster_capacity_providers" "bia_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.bia_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "bia_log_group" {
  name              = "/ecs/bia-tf"
  retention_in_days = 7

  tags = {
    Name    = "bia-log-group"
    Project = "BIA"
  }
}

# ECS Task Definition seguindo nomenclatura do projeto (bia-tf)
resource "aws_ecs_task_definition" "bia_task" {
  family                   = "bia-tf"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "bia-container"
      image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/bia-app:latest"

      memory = 512

      portMappings = [
        {
          hostPort      = 0
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "8080"
        },
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_user
        },
        {
          name  = "DB_PASS"
          value = var.db_password
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/api/versao || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bia_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = {
    Name    = "bia-tf"
    Project = "BIA"
  }
}

# ECS Service seguindo nomenclatura do projeto
resource "aws_ecs_service" "bia_service" {
  name            = "bia-service"
  cluster         = aws_ecs_cluster.bia_cluster.id
  task_definition = aws_ecs_task_definition.bia_task.arn
  desired_count   = 1
  launch_type     = "EC2"

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 50
  }

  placement_constraints {
    type = "distinctInstance"
  }

  tags = {
    Name    = "bia-service"
    Project = "BIA"
  }

  depends_on = [
    aws_autoscaling_group.ecs_asg,
    aws_ecs_cluster_capacity_providers.bia_cluster_capacity_providers
  ]
}
