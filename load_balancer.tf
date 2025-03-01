resource "aws_lb" "ecs_alb" {
  name               = "fiap-devops-ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fiap_devops_security_group.id]
  subnets            = [aws_subnet.fiap_devops_public_subnet.id, aws_subnet.fiap_devops_public_subnet_2.id]
  tags = {
    Name = "fiap-devops-ecs-alb"
  }
}

resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fiap_devops_ecs_tg.arn
  }
}

resource "aws_lb_target_group" "fiap_devops_ecs_tg" {
  name        = "fiap-devops-ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.fiap_devops_vpc.id

  health_check {
    path = "/"
  }
}