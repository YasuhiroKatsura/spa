# -----VPC-----
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_conf.vpc.cidr_block
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
}

# -----Subnets (public)-----
resource "aws_subnet" "public" {
  for_each = var.vpc_conf.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = "${var.common.region}${each.key}" # ap-northeast-1a or ap-northeast-1c
  map_public_ip_on_launch = "false"
  tags = {
    Name = "${var.common.project_name}-pub-sn-${each.key}"
  }
}

# -----Subnets (private)-----
resource "aws_subnet" "private" {
  for_each = var.vpc_conf.private_subnets

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
  count  = length(var.vpc_conf.public_subnets) > 0 ? 1 : 0 # public snがある場合のみ作成
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.common.project_name}-igw"
  }
}

# -----Route Table (public)-----
resource "aws_route_table" "public" {
  count  = length(var.vpc_conf.public_subnets) > 0 ? 1 : 0
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
  for_each       = var.vpc_conf.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# -----Route Table (private)-----
resource "aws_route_table" "private" {
  count  = length(var.vpc_conf.private_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.common.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = var.vpc_conf.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[0].id
}
