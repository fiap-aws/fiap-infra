# FIAP DEVOPS VPC
resource "aws_vpc" "fiap_devops_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "fiap_devops_vpc"
  }
}

# Public Subnet
resource "aws_subnet" "fiap_devops_public_subnet" {
  vpc_id     = aws_vpc.fiap_devops_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "fiap_devops_public_subnet"
  }
}

resource "aws_subnet" "fiap_devops_public_subnet_2" {
  vpc_id     = aws_vpc.fiap_devops_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "fiap_devops_public_subnet_2"
  }
}

# Public Subnet
resource "aws_subnet" "fiap_devops_public_subnet" {
  vpc_id     = aws_vpc.fiap_devops_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "fiap_devops_public_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "fiap_devops_igw" {
  vpc_id = aws_vpc.fiap_devops_vpc.id

  tags = {
    Name = "fiap_devops_igw"
  }
}

# Route Table
resource "aws_route_table" "fiap_devops_rt" {
  vpc_id = aws_vpc.fiap_devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fiap_devops_igw.id
  }

  tags = {
    Name = "fiap_devops_rt"
  }
}

resource "aws_route" "fiap_devops_routetointernet" {
  route_table_id            = aws_route_table.fiap_devops_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.fiap_devops_igw.id
}

resource "aws_route_table_association" "fiap_devops_pub_association" {
  subnet_id      = aws_subnet.fiap_devops_public_subnet.id
  route_table_id = aws_route_table.fiap_devops_rt.id
}

#SG
resource "aws_security_group" "fiap_devops_security_group" {
    vpc_id = aws_vpc.fiap_devops_vpc.id

    tags = {
    	Name = "fiap_devops_security_group"
    } 
}

#Egress Rule for SG
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.fiap_devops_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}