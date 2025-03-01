# AWS Launch Template
resource "aws_launch_template" "fiap_devops_ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = "ami-05b10e08d247fb927"
  instance_type = "t2.micro"

  key_name               = "fiap_keypair"
  vpc_security_group_ids = [aws_security_group.fiap_devops_security_group.id]
  iam_instance_profile {
    name = "ecsInstanceRole"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-instance"
    }
  }
}

resource "aws_autoscaling_group" "fiap_devops_ecs_asg" {
  vpc_zone_identifier = [aws_subnet.fiap_devops_public_subnet.id]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1

  launch_template {
    id      = aws_launch_template.fiap_devops_ecs_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

