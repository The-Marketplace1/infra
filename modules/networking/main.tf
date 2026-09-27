################################################################################
# VPC Module
# Creates a production-grade VPC with public/private subnets, NAT gateways,
# internet gateway, and all associated routing.
################################################################################

locals {
  name = "${var.project}-${var.environment}"

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + var.az_count)]
}

data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# VPC
################################################################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = local.name
    "kubernetes.io/cluster/${local.name}" = "shared"
  })
}

################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${local.name}-igw" })
}

################################################################################
# Public Subnets
################################################################################
resource "aws_subnet" "public" {
  count = length(local.azs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${local.name}-public-${local.azs[count.index]}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

################################################################################
# Private Subnets
################################################################################
resource "aws_subnet" "private" {
  count = length(local.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${local.name}-private-${local.azs[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  })
}

################################################################################
# NAT Gateway (one per AZ for HA)
################################################################################
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(local.azs)
  domain = "vpc"

  tags = merge(var.tags, { Name = "${local.name}-nat-eip-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.single_nat_gateway ? 1 : length(local.azs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "${local.name}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count  = length(local.azs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
  }

  tags = merge(var.tags, { Name = "${local.name}-private-rt-${count.index}" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

################################################################################
# Security Groups — baseline
################################################################################
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "ALB — allow HTTPS inbound, unrestricted egress"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-alb-sg" })
}

resource "aws_security_group" "nodes" {
  name        = "${local.name}-node-sg"
  description = "EKS worker node security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "From ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Node-to-node"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-node-sg" })
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "RDS — allow PostgreSQL from nodes only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL from nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-rds-sg" })
}

resource "aws_security_group" "redis" {
  name        = "${local.name}-redis-sg"
  description = "ElastiCache — allow Redis from nodes only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Redis from nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-redis-sg" })
}

