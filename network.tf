data "aws_availability_zones" "available" { state = "available" }

locals {
  azs_count = 2
  azs_names = data.aws_availability_zones.available.names
}

resource "aws_vpc" "fiap_devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "fiap-devops-vpc" }
}

resource "aws_subnet" "fiap_devops_public_subnet" {
  count                   = local.azs_count
  vpc_id                  = aws_vpc.fiap_devops_vpc.id
  availability_zone       = local.azs_names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.fiap_devops_vpc.cidr_block, 8, 10 + count.index)
  map_public_ip_on_launch = true
  tags                    = { Name = "fiap-devops-public-subnet-${local.azs_names[count.index]}" }
}

resource "aws_internet_gateway" "fiap_devops_igw" {
  vpc_id = aws_vpc.fiap_devops_vpc.id
  tags   = { Name = "fiap-devops-igw" }
}

resource "aws_eip" "fiap_devops_eip" {
  count      = local.azs_count
  depends_on = [aws_internet_gateway.fiap_devops_igw]
  tags       = { Name = "fiap-devops-eip-${local.azs_names[count.index]}" }
}

resource "aws_route_table" "fiap_devops_rt" {
  vpc_id = aws_vpc.fiap_devops_vpc.id
  tags   = { Name = "fiap-devops-rt-public" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fiap_devops_igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = local.azs_count
  subnet_id      = aws_subnet.fiap_devops_public_subnet[count.index].id
  route_table_id = aws_route_table.fiap_devops_rt.id
}

resource "aws_security_group" "fiap_devops_ecs_node_sg" {
  name_prefix = "fiap-devops-ecs-node-sg-"
  vpc_id      = aws_vpc.fiap_devops_vpc.id
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_ecs_node" {
  security_group_id = aws_security_group.fiap_devops_ecs_node_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
}

resource "aws_security_group" "fiap_devops_ecs_task_sg" {
  name_prefix = "fiap-devops-ecs-task-sg-"
  description = "Allow all traffic within the VPC"
  vpc_id      = aws_vpc.fiap_devops_vpc.id
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_ecs_task" {
  security_group_id = aws_security_group.fiap_devops_ecs_task_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_ecs_task" {
  security_group_id = aws_security_group.fiap_devops_ecs_task_sg.id

  cidr_ipv4   = aws_vpc.fiap_devops_vpc.cidr_block
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
}

resource "aws_security_group" "fiap_devops_alb_sg" {
  name_prefix = "fiap-devops-alb-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = aws_vpc.fiap_devops_vpc.id
}

resource "aws_vpc_security_group_egress_rule" "allow_egress_alb" {
  security_group_id = aws_security_group.fiap_devops_alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
}

resource "aws_vpc_security_group_ingress_rule" "allow_ingress_alb" {
  security_group_id = aws_security_group.fiap_devops_alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}