output "vpc_id" {
  description = "ID of the network VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the network VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_route_table_id" {
  description = "Route table of the public subnet, where the prod route is added."
  value       = module.vpc.public_route_table_ids[0]
}

output "zone_id" {
  description = "ID of the public Route53 zone."
  value       = module.zone.id
}

output "zone_name_servers" {
  description = "Name servers to set at the domain registrar."
  value       = module.zone.name_servers
}

output "dns_record_writer_role_arn" {
  description = "Role in this account that the prod apply role assumes to write DNS records."
  value       = module.dns_record_writer.arn
}

output "vpc_peering_manager_role_arn" {
  description = "Role in this account that the prod apply role assumes to accept the peering and add routes."
  value       = module.vpc_peering_manager.arn
}

output "network_reader_role_arn" {
  description = "Read-only role in this account that the prod plan role assumes to plan cross-account resources."
  value       = module.network_reader.arn
}

output "tailscale_auth_key_parameter" {
  description = "SSM parameter that holds the Tailscale auth key."
  value       = aws_ssm_parameter.tailscale_auth_key.name
}

output "tailscale_router_instance_id" {
  description = "Instance ID of the Tailscale subnet router."
  value       = module.tailscale_router.id
}
