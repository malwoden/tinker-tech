resource "aws_ram_resource_share" "hub_tgw" {
  name = "hub-transit-gateway"

  tags = {
    Name = "hub-transit-gateway"
  }
}

resource "aws_ram_resource_association" "hub_tgw" {
  resource_arn       = aws_ec2_transit_gateway.hub.arn
  resource_share_arn = aws_ram_resource_share.hub_tgw.id
}

resource "aws_ram_principal_association" "hub_tgw_to_spoke" {
  for_each           = local.spoke_accounts
  principal          = each.value.account_id
  resource_share_arn = aws_ram_resource_share.hub_tgw.id
}

resource "aws_ec2_transit_gateway" "hub" {
  description = "hub"
  tags = {
    Name = "hub"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = values(module.vpc.private_subnet_ids)
  transit_gateway_id = aws_ec2_transit_gateway.hub.id
  vpc_id             = module.vpc.vpc_id
}

resource "aws_ec2_transit_gateway_route" "hub_outbound" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.hub.association_default_route_table_id
}
