locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
  })
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = var.vpc_name })
}

# Public subnet (single AZ selection)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, 0)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = var.availability_zone

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-public" })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-igw" })
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

## Optional private subnet and NAT gateway (for production)
resource "aws_subnet" "private" {
  count = var.create_private_subnet ? 1 : 0
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(aws_vpc.this.cidr_block, 8, var.private_subnet_suffix)
  map_public_ip_on_launch = false
  availability_zone = var.availability_zone

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-private" })
}

resource "aws_eip" "nat_eip" {
  count = var.create_nat_gateway ? 1 : 0
  vpc   = true
  tags = merge(local.common_tags, { Name = "${var.vpc_name}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  count = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public.id
  tags = merge(local.common_tags, { Name = "${var.vpc_name}-nat" })
}

resource "aws_route_table" "private" {
  count = var.create_private_subnet ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.create_nat_gateway ? aws_nat_gateway.nat[0].id : aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, { Name = "${var.vpc_name}-private-rt" })
}

resource "aws_route_table_association" "private_assoc" {
  count = var.create_private_subnet ? 1 : 0
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private[0].id
}
