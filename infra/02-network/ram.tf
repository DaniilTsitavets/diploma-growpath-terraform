resource "aws_ram_resource_share" "private_subnets" {
  name                      = "growpath-private-subnets"
  allow_external_principals = false
}

resource "aws_ram_resource_association" "private_subnets" {
  for_each = { for i, arn in module.vpc.private_subnet_arns : tostring(i) => arn }

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.private_subnets.arn
}

resource "aws_ram_principal_association" "prod" {
  principal          = local.prod_account_id
  resource_share_arn = aws_ram_resource_share.private_subnets.arn
}
