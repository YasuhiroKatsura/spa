# -----VPC-----
resource "aws_vpc" "this" {
  cidr_block           = var.network.vpc.cidr_block
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "${var.common.project_name}-vpc"
  }
}

# -----Subnets (public)-----
resource "aws_subnet" "public" {
  for_each = var.network.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = "${var.common.region}${each.key}"
  map_public_ip_on_launch = "false"
  tags = {
    Name = "${var.common.project_name}-pub-sn-${each.key}"
  }
}

# -----Subnets (private)-----
resource "aws_subnet" "private" {
  for_each = var.network.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = "${var.common.region}${regex("[ac]$", each.key)}"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "${var.common.project_name}-pvt-sn-${each.key}"
  }
}

# -----Internet Gateway-----
resource "aws_internet_gateway" "this" {
  count  = length(var.network.public_subnets) > 0 ? 1 : 0 # public snがある場合のみ作成
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.common.project_name}-igw"
  }
}

# -----Route Table (public)-----
resource "aws_route_table" "public" {
  count  = length(var.network.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0" # XXX ある程度利用者でルール決めれるようにしたい
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = {
    Name = "${var.common.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = var.network.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# -----Route Table (private)-----
resource "aws_route_table" "private" {
  count  = length(var.network.private_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.common.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = var.network.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_security_group" "api_tasks" {
  name        = "${var.common.project_name}-sg-on-ecs-service4api"
  description = "Security group for the API ECS service"
  vpc_id      = aws_vpc.this.id
  egress      = []
}

resource "aws_security_group" "api_alb" {
  name        = "${var.common.project_name}-sg-on-alb-to-ecs4api"
  description = "Security group for the private API load balancer"
  vpc_id      = aws_vpc.this.id
  egress      = []
}

resource "aws_security_group" "api_gateway_vpc_link" {
  name        = "${var.common.project_name}-sg-on-vpc-link"
  description = "Security group for the API Gateway VPC Link"
  vpc_id      = aws_vpc.this.id
  egress      = []
}

resource "aws_security_group" "database" {
  name        = "${var.common.project_name}-sg-on-rds-aurora"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = aws_vpc.this.id
  egress      = []
}

resource "aws_security_group" "frontend_alb" {
  name        = "${var.common.project_name}-sg-on-alb-to-s34front"
  description = "Security group for the public frontend load balancer"
  vpc_id      = aws_vpc.this.id
  egress      = []
}

resource "aws_security_group" "frontend_endpoint" {
  name        = "${var.common.project_name}-sg-on-vpcendpt-to-s34front"
  description = "Security group for the frontend S3 VPC endpoint"
  vpc_id      = aws_vpc.this.id
  egress      = []
}

resource "aws_vpc_security_group_ingress_rule" "api_alb_from_vpc_link" {
  security_group_id            = aws_security_group.api_alb.id
  description                  = "Allow API Gateway VPC Link traffic"
  referenced_security_group_id = aws_security_group.api_gateway_vpc_link.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "api_alb_all" {
  security_group_id = aws_security_group.api_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "api_tasks_from_alb" {
  security_group_id            = aws_security_group.api_tasks.id
  description                  = "Allow API load balancer traffic to ECS tasks"
  referenced_security_group_id = aws_security_group.api_alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "api_tasks_all" {
  security_group_id = aws_security_group.api_tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "api_gateway_to_alb" {
  security_group_id            = aws_security_group.api_gateway_vpc_link.id
  description                  = "Allow API Gateway VPC Link traffic to the API load balancer"
  referenced_security_group_id = aws_security_group.api_alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "database_from_api" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow PostgreSQL connections from the API tasks"
  referenced_security_group_id = aws_security_group.api_tasks.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "database_all" {
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "frontend_endpoint_from_alb" {
  security_group_id            = aws_security_group.frontend_endpoint.id
  description                  = "Allow HTTPS from the frontend load balancer"
  referenced_security_group_id = aws_security_group.frontend_alb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "frontend_endpoint_all" {
  security_group_id = aws_security_group.frontend_endpoint.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "frontend_alb_http" {
  security_group_id = aws_security_group.frontend_alb.id
  description       = "Allow public HTTP traffic"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "frontend_alb_all" {
  security_group_id = aws_security_group.frontend_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
