# FIAP DEVOPS VPC
resource "aws_vpc" "fiap_devops_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "fiap_blog_vpc"
  }
}

# Public Subnet
resource "aws_subnet" "fiap_public_subnet" {
  vpc_id     = aws_vpc.fiap_devops_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "tcb_blog_public_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "fiap_devops_igw" {
  vpc_id = aws_vpc.fiap_devops_vpc.id
}

# Route Table
resource "aws_route_table" "fiap_devops_rt" {
  vpc_id = aws_vpc.fiap_devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fiap_devops_igw.id
  }

}

resource "aws_route" "tcb_blog_routetointernet" {
  route_table_id            = aws_route_table.fiap_devops_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.fiap_devops_igw.id
}

resource "aws_route_table_association" "tcb_blog_pub_association" {
  subnet_id      = aws_subnet.fiap_devops_public_subnet.id
  route_table_id = aws_route_table.fiap_devops_rt.id
}