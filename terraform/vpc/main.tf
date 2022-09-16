locals {
  app_env_description = "${var.app_name} (${var.env})"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "Main VPC - ${local.app_env_description}"
  }
}

resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index].cidr
  availability_zone = var.private_subnets[count.index].az

  tags = {
    App                                         = var.app_name
    Env                                         = var.env
    Name                                        = "Private Subnet ${count.index} - ${local.app_env_description}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets[count.index].cidr
  availability_zone = var.public_subnets[count.index].az

  tags = {
    App                                         = var.app_name
    Env                                         = var.env
    Name                                        = "Public Subnet ${count.index} - ${local.app_env_description}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "Internet Gateway - ${local.app_env_description}"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "NAT Elastic IP - ${local.app_env_description}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id


  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "NAT Gateway - ${local.app_env_description}"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "Private Route Table - ${local.app_env_description}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "Public Route Table - ${local.app_env_description}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}
