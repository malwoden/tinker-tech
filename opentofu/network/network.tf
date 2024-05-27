# vpc: 10.0.0.0/20
# a:
# 10.0.0.0/23 10.0.0.0 - 10.0.1.255 10.0.0.1 - 10.0.1.254 510 - Private
# 10.0.2.0/24 10.0.2.0 - 10.0.2.255 10.0.2.1 - 10.0.2.254 254 - Public
# 10.0.3.0/24 10.0.3.0 - 10.0.3.255 10.0.3.1 - 10.0.3.254 254 - Spare
# b:
# 10.0.4.0/23 10.0.4.0 - 10.0.5.255 10.0.4.1 - 10.0.5.254 510 - Private
# 10.0.6.0/24 10.0.6.0 - 10.0.6.255 10.0.6.1 - 10.0.6.254 254 - Public
# 10.0.7.0/24 10.0.7.0 - 10.0.7.255 10.0.7.1 - 10.0.7.254 254 - Spare
# c:
# 10.0.8.0/23 10.0.8.0 - 10.0.9.255 10.0.8.1 - 10.0.9.254 510 - Private
# 10.0.10.0/24 10.0.10.0 - 10.0.10.255 10.0.10.1 - 10.0.10.254 254 - Public
# 10.0.11.0/24 10.0.11.0 - 10.0.11.255 10.0.11.1 - 10.0.11.254 254 - Spare
# Spare:
# 10.0.12.0/22 10.0.12.0 - 10.0.15.255 10.0.12.1 - 10.0.15.254 1022

locals {
  hub_cidr_block = "10.0.0.0/20"
  hub_private_subnets = {
    "a" = "10.0.0.0/23",
    "b" = "10.0.4.0/23",
    "c" = "10.0.8.0/23"
  }
  hub_public_subnets = {
    "a" = "10.0.2.0/24",
    "b" = "10.0.6.0/24",
    "c" = "10.0.10.0/24",
  }
}

resource "aws_vpc" "hub" {
  cidr_block = local.hub_cidr_block

  tags = {
    Name = "hub"
  }
}

resource "aws_default_security_group" "hub" {
  vpc_id = aws_vpc.hub.id
}

resource "aws_route_table" "hub_private" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub_nat_a.id
  }

  tags = {
    Name = "hub-private"
  }
}

resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub_igw.id
  }

  tags = {
    Name = "hub-public"
  }
}

resource "aws_subnet" "hub_private" {
  for_each = local.hub_private_subnets

  vpc_id            = aws_vpc.hub.id
  cidr_block        = each.value
  availability_zone = "eu-west-2${each.key}"

  tags = {
    Name = "hub-private-${each.key}"
  }
}

resource "aws_subnet" "hub_public" {
  for_each = local.hub_public_subnets

  vpc_id            = aws_vpc.hub.id
  cidr_block        = each.value
  availability_zone = "eu-west-2${each.key}"

  tags = {
    Name = "hub-public-${each.key}"
  }
}

resource "aws_route_table_association" "hub_private" {
  for_each = local.hub_private_subnets

  subnet_id      = aws_subnet.hub_private[each.key].id
  route_table_id = aws_route_table.hub_private.id
}

resource "aws_route_table_association" "hub_public" {
  for_each = local.hub_public_subnets

  subnet_id      = aws_subnet.hub_public[each.key].id
  route_table_id = aws_route_table.hub_public.id
}

# single nat gateway to keep the costs down. All private subnets are routed to this
resource "aws_eip" "hub_nat_a" {
  #checkov:skip=CKV2_AWS_19:Attached to the NAT Gateway
  tags = {
    Name = "hub-nat-a"
  }
}

resource "aws_internet_gateway" "hub_igw" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "hub-igw"
  }
}

resource "aws_nat_gateway" "hub_nat_a" {
  allocation_id = aws_eip.hub_nat_a.id
  subnet_id     = aws_subnet.hub_public["a"].id

  tags = {
    Name = "hub-nat"
  }

  depends_on = [aws_internet_gateway.hub_igw]
}
