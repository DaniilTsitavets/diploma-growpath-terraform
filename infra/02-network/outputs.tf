output "vpc_id" {
  description = "ID of the shared VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the shared VPC."
  value       = module.vpc.vpc_cidr_block
}

output "azs" {
  description = "Availability zones used by the subnets."
  value       = module.vpc.azs
}

output "private_subnet_ids" {
  description = "IDs of the private subnets shared with the prod account."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnets
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

output "tailscale_auth_key_parameter" {
  description = "SSM parameter that holds the Tailscale auth key."
  value       = aws_ssm_parameter.tailscale_auth_key.name
}

output "tailscale_router_instance_id" {
  description = "Instance ID of the Tailscale subnet router."
  value       = module.tailscale_router.id
}
