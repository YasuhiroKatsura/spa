resource "aws_subnet" "this" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge({ Name = var.subnet_name }, var.tags)
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id
  tags   = merge({ Name = "${var.subnet_name}-rt" }, var.tags)
}

resource "aws_route" "this" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}