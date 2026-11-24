resource "aws_vpc_peering_connection" "network" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = local.network_vpc_id
  peer_owner_id = local.network_account_id
  peer_region   = var.region

  tags = { Name = "growpath-prod-to-network" }
}

resource "aws_vpc_peering_connection_accepter" "network" {
  provider = aws.network

  vpc_peering_connection_id = aws_vpc_peering_connection.network.id
  auto_accept               = true

  tags = { Name = "growpath-network-to-prod" }
}

resource "aws_route" "prod_to_network" {
  for_each = { for i, id in module.vpc.private_route_table_ids : tostring(i) => id }

  route_table_id            = each.value
  destination_cidr_block    = local.network_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.network.id

  depends_on = [aws_vpc_peering_connection_accepter.network]
}

resource "aws_route" "network_to_prod" {
  provider = aws.network

  route_table_id            = local.network_public_rt_id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.network.id

  depends_on = [aws_vpc_peering_connection_accepter.network]
}
