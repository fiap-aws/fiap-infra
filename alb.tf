# --- ALB ---

resource "aws_lb" "fiap_devops_alb" {
  name               = "fiap-devops-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.fiap_devops_public_subnet[*].id
  security_groups    = [aws_security_group.fiap_devops_alb_sg.id]
}

resource "aws_lb_target_group" "fiap_devops_alb_tg" {
  name_prefix = "app-"
  vpc_id      = aws_vpc.fiap_devops_vpc.id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = 80
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.fiap_devops_alb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fiap_devops_alb_tg.id
  }
}

output "alb_url" {
  value = aws_lb.fiap_devops_alb.dns_name
}