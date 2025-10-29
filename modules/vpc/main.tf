
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, { Name = "vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "vpc-igw" })
}

data "aws_availability_zones" "available" {}
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_subnet" "public" {
  for_each = toset(local.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_newbits, index(local.azs, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "public-${each.key}",
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = toset(local.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_newbits, index(local.azs, each.key) + 10)
  availability_zone = each.key
  tags = merge(var.tags, {
    Name = "private-${each.key}",
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "public-rt" })
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

locals {
  first_public_subnet_id = values(aws_subnet.public)[0].id
}

resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  count         = var.single_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = local.first_public_subnet_id
  tags          = merge(var.tags, { Name = "vpc-nat" })
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "private-rt" })
}

resource "aws_route" "private_nat" {
  count                  = var.single_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
