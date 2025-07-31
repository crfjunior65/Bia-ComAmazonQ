# Otimização de Custos - Spot Instances para ECS
# Economia estimada: $3.79/mês (50% de redução)

resource "aws_launch_template" "ecs_spot_template" {
  name_prefix   = "bia-ecs-spot-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.micro"
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.bia_web.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  # Configuração para Spot Instance
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price                      = "0.0052"  # 50% do preço On-Demand
      spot_instance_type            = "one-time"
      instance_interruption_behavior = "terminate"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=custer-bia >> /etc/ecs/ecs.config
    yum update -y
    yum install -y curl
    
    # Script para lidar com interrupção de Spot
    cat > /opt/spot-interruption-handler.sh << 'SCRIPT'
    #!/bin/bash
    while true; do
      TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
      if curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/spot/instance-action 2>/dev/null | grep -q terminate; then
        echo "Spot instance termination notice received"
        # Drenar tasks do ECS
        aws ecs update-container-instances-state --cluster custer-bia --container-instances $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id) --status DRAINING
        sleep 120
      fi
      sleep 5
    done
    SCRIPT
    
    chmod +x /opt/spot-interruption-handler.sh
    nohup /opt/spot-interruption-handler.sh &
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "bia-ecs-spot-instance"
      Project = "BIA"
      Type    = "spot"
    }
  }

  tags = {
    Name    = "bia-ecs-spot-template"
    Project = "BIA"
  }
}

# Mixed Instance Policy para maior disponibilidade
resource "aws_autoscaling_group" "ecs_spot_asg" {
  name                = "bia-ecs-spot-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = []
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs_spot_template.id
        version           = "$Latest"
      }
      
      override {
        instance_type = "t3.micro"
      }
      override {
        instance_type = "t3a.micro"  # Alternativa mais barata
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0  # 100% Spot
      spot_allocation_strategy                 = "diversified"
      spot_instance_pools                      = 2
      spot_max_price                          = "0.0052"
    }
  }

  tag {
    key                 = "Name"
    value               = "bia-ecs-spot-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Project"
    value               = "BIA"
    propagate_at_launch = true
  }

  tag {
    key                 = "CostOptimized"
    value               = "true"
    propagate_at_launch = true
  }
}
