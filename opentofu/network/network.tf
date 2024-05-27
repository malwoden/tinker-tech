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

module "vpc" {
  source     = "../modules/vpc"
  name       = "hub"
  cidr_block = "10.0.0.0/20"
  private_subnets = {
    "a" = "10.0.0.0/23",
    "b" = "10.0.4.0/23",
    "c" = "10.0.8.0/23"
  }
  public_subnets = {
    "a" = "10.0.2.0/24",
    "b" = "10.0.6.0/24",
    "c" = "10.0.10.0/24",
  }
}

resource "aws_route_table" "hub_private" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub_nat_a.id
  }

  tags = {
    Name = "hub-private"
  }
}

resource "aws_route_table" "hub_public" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub_igw.id
  }

  dynamic "route" {
    for_each = local.spoke_accounts
    content {
      cidr_block         = route.value.vpc_cidr
      transit_gateway_id = aws_ec2_transit_gateway.hub.id
    }
  }

  tags = {
    Name = "hub-public"
  }
}

resource "aws_route_table_association" "hub_private" {
  for_each = module.vpc.private_subnet_ids

  subnet_id      = each.value
  route_table_id = aws_route_table.hub_private.id
}

resource "aws_route_table_association" "hub_public" {
  for_each = module.vpc.public_subnet_ids

  subnet_id      = each.value
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
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "hub-igw"
  }
}

resource "aws_nat_gateway" "hub_nat_a" {
  allocation_id = aws_eip.hub_nat_a.id
  subnet_id     = module.vpc.public_subnet_ids["a"]

  tags = {
    Name = "hub-nat"
  }

  depends_on = [aws_internet_gateway.hub_igw]
}
