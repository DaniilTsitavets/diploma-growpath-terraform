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

output "s3_buckets" {
  description = "Names of the application buckets."
  value = {
    frontend = module.s3_frontend.s3_bucket_id
    media    = module.s3_media.s3_bucket_id
    photos   = module.s3_photos.s3_bucket_id
  }
}

output "vector_bucket_name" {
  description = "Name of the S3 Vectors bucket for the knowledge base."
  value       = aws_s3vectors_vector_bucket.kb.vector_bucket_name
}

output "frontend_ci_role_arn" {
  description = "Role the frontend repository assumes to deploy the SPA."
  value       = module.frontend_ci_role.arn
}

output "backend_ci_role_arn" {
  description = "Role the backend repository assumes to push images."
  value       = module.backend_ci_role.arn
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Private API server endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "karpenter_queue_name" {
  description = "SQS queue Karpenter reads interruption events from."
  value       = module.karpenter.queue_name
}

output "karpenter_node_role_name" {
  description = "IAM role of the nodes Karpenter launches."
  value       = module.karpenter.node_iam_role_name
}

output "platform_alb_security_group_id" {
  description = "Security group for the admin-tools ALB Ingress annotation."
  value       = module.platform_alb_sg.id
}

output "platform_certificate_arn" {
  description = "Regional ACM certificate for the platform hosts."
  value       = aws_acm_certificate_validation.platform.certificate_arn
}

output "topic_arns" {
  description = "SNS topic ARNs by name, for the service environment variables."
  value       = local.topic_arns
}

output "queue_urls" {
  description = "SQS queue URLs by name, for the service environment variables."
  value       = { for name, queue in module.queue : name => queue.queue_url }
}
