# vpc: 10.8.0.0/18
# a:
# 10.8.0.0/21 10.8.0.0 - 10.8.7.255 2046 - Private
# 10.8.8.0/24 10.8.8.0 - 10.8.8.255 254 - Public
# b:
# 10.8.16.0/21 10.8.16.0 - 10.8.23.255 2046 - Private
# 10.8.24.0/24 10.8.24.0 - 10.8.27.255 254 - Public
# c:
# 10.8.32.0/21 10.8.32.0 - 10.8.39.255 2046 - Private
# 10.8.40.0/24 10.8.40.0 - 10.8.43.255 254 - Public
# Spare:
# 10.8.48.0/20 10.8.48.0 - 10.8.63.255 4094 - Spare

module "vpc" {
  source     = "../modules/vpc"
  name       = "apps"
  cidr_block = "10.8.0.0/18"
  private_subnets = {
    "a" = "10.8.0.0/21",
    "b" = "10.8.16.0/21",
    "c" = "10.8.32.0/21",
  }
  public_subnets = {
    "a" = "10.8.8.0/24",
    "b" = "10.8.24.0/24",
    "c" = "10.8.40.0/24",
  }
}

data "aws_ec2_transit_gateway" "hub" {
  filter {
    name   = "tag:Name"
    values = ["hub"]
  }
  provider = aws.network
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = values(module.vpc.private_subnet_ids)
  transit_gateway_id = data.aws_ec2_transit_gateway.hub.id
  vpc_id             = module.vpc.vpc_id
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "apps_hub_accepter" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.hub.id
  provider                      = aws.network
}

resource "aws_internet_gateway" "apps_igw" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "apps-igw"
  }
}

resource "aws_route_table" "apps_private" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = data.aws_ec2_transit_gateway.hub.id
  }

  tags = {
    Name = "apps-private"
  }
}

resource "aws_route_table" "apps_public" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.apps_igw.id
  }

  tags = {
    Name = "apps-public"
  }
}

resource "aws_route_table_association" "apps_private" {
  for_each = module.vpc.private_subnet_ids

  subnet_id      = each.value
  route_table_id = aws_route_table.apps_private.id
}

resource "aws_route_table_association" "apps_public" {
  for_each = module.vpc.public_subnet_ids

  subnet_id      = each.value
  route_table_id = aws_route_table.apps_public.id
}
