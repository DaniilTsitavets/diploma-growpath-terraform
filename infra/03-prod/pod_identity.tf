module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.11"

  name            = "${var.cluster_name}-aws-load-balancer-controller"
  use_name_prefix = false

  attach_aws_lb_controller_policy = true

  associations = { for cluster in module.eks[*].cluster_name : "this" => {
    cluster_name    = cluster
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
  } }
}

module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.11"

  name            = "${var.cluster_name}-ebs-csi"
  use_name_prefix = false

  attach_aws_ebs_csi_policy = true
}

module "external_dns_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.11"

  name            = "${var.cluster_name}-external-dns"
  use_name_prefix = false

  attach_custom_policy = true
  policy_statements = [{
    sid       = "AssumeDnsRecordWriter"
    actions   = ["sts:AssumeRole", "sts:TagSession"]
    resources = ["arn:aws:iam::${local.network_account_id}:role/DnsRecordWriter"]
  }]
}

module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.11"

  name            = "${var.cluster_name}-external-secrets"
  use_name_prefix = false

  attach_custom_policy = true
  policy_statements = [{
    sid       = "ReadProjectSecrets"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.cluster_name}/*"]
  }]

  associations = { for cluster in module.eks[*].cluster_name : "this" => {
    cluster_name    = cluster
    namespace       = "external-secrets"
    service_account = "external-secrets"
  } }
}
