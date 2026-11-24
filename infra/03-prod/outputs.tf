output "vpc_id" {
  description = "ID of the prod VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the prod VPC."
  value       = module.vpc.vpc_cidr_block
}

output "azs" {
  description = "Availability zones used by the subnets."
  value       = module.vpc.azs
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnets
}

output "peering_connection_id" {
  description = "ID of the peering connection to the network VPC."
  value       = aws_vpc_peering_connection.network.id
}

output "ecr_repository_urls" {
  description = "ECR repository URL per service."
  value       = { for name, repo in module.ecr : name => repo.repository_url }
}
