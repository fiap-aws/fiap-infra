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

# --- ECS Task Definition ---

resource "aws_ecs_task_definition" "fiap_devops_task_definition" {
  family             = "simple-http-app"
  task_role_arn      = aws_iam_role.fiap_devops_ecs_task_role.arn
  execution_role_arn = aws_iam_role.fiap_devops_ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 256

  container_definitions = jsonencode([{
    name         = "http-app",
    image        = "emunari/simple-docker-image:latest",
    essential    = true,
    portMappings = [{ containerPort = 80, hostPort = 80 }],
  }])
}

# --- ECS Service ---

resource "aws_ecs_service" "app" {
  name            = "http-app"
  cluster         = aws_ecs_cluster.fiap_devops_ecs_cluster.id
  task_definition = aws_ecs_task_definition.fiap_devops_task_definition.arn
  desired_count   = 2

  network_configuration {
    security_groups = [aws_security_group.fiap_devops_ecs_task_sg.id]
    subnets         = aws_subnet.fiap_devops_public_subnet[*].id
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.fiap_devops_ecs_capacity_provider.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_target_group.fiap_devops_alb_tg]

  load_balancer {
    target_group_arn = aws_lb_target_group.fiap_devops_alb_tg.arn
    container_name   = "http-app"
    container_port   = 80
  }
}