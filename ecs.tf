resource "aws_ecs_cluster" "fiap_devops_ecs_cluster" {
  name = "fiap-devops-ecs-cluster"
}

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "fiap_devops_ecs_ec2" {
  name_prefix            = "fiap-devops-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.fiap_devops_ecs_node_sg.id]

  iam_instance_profile { arn = aws_iam_instance_profile.fiap_devops_ecs_node.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.fiap_devops_ecs_cluster.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

resource "aws_autoscaling_group" "fiap_devops_ecs_asg" {
  name_prefix               = "fiap-devops-ecs-asg-"
  vpc_zone_identifier       = aws_subnet.fiap_devops_public_subnet[*].id
  min_size                  = 1
  max_size                  = 3
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.fiap_devops_ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "fiap-devops-ecs-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "fiap_devops_ecs_capacity_provider" {
  name = "fiap-devops-ecs-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.fiap_devops_ecs_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.fiap_devops_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.fiap_devops_ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.fiap_devops_ecs_capacity_provider.name
    base              = 1
    weight            = 100
  }
}