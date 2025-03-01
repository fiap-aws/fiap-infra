resource "aws_ecs_cluster" "fiap_devops_ecs_cluster" {
 name = "my-ecs-cluster"
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "fiap_devops_capacity_ecs"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.fiap_devops_ecs_asg.arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 3
   }
 }
}

resource "aws_ecs_cluster_capacity_providers" "fiap_devops_ecs_cluster_capacity" {
 cluster_name = aws_ecs_cluster.fiap_devops_ecs_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
}

resource "aws_ecs_task_definition" "fiap_devops_task_definition" {
  family = "fiap-devops-task-definition"
  container_definitions = jsonencode([
    {
      name      = "simple-html-app"
      image     = "docker.io/emunari/simple-docker-image"
      cpu       = 1
      memory    = 128
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }
}

resource "aws_ecs_service" "ecs_service" {
 name            = "my-ecs-service"
 cluster         = aws_ecs_cluster.fiap_devops_ecs_cluster.id
 task_definition = aws_ecs_task_definition.fiap_devops_task_definition.arn
 desired_count   = 2

 network_configuration {
   subnets         = [aws_subnet.fiap_devops_public_subnet.id]
   security_groups = [aws_security_group.fiap_devops_security_group.id]
 }

 force_new_deployment = true
 placement_constraints {
   type = "distinctInstance"
 }

 triggers = {
   redeployment = timestamp()
 }

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
   weight            = 100
 }

 load_balancer {
   target_group_arn = aws_lb_target_group.fiap_devops_ecs_tg.arn
   container_name   = "fiap_devops_app"
   container_port   = 80
 }

 depends_on = [aws_autoscaling_group.fiap_devops_ecs_asg]
}