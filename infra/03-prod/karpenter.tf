module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.30"

  count = var.enable_platform ? 1 : 0

  cluster_name = module.eks[0].cluster_name

  iam_role_name            = "${var.cluster_name}-karpenter-controller"
  iam_role_use_name_prefix = false

  queue_name = "${var.cluster_name}-karpenter"

  node_iam_role_name            = "${var.cluster_name}-karpenter-node"
  node_iam_role_use_name_prefix = false

  create_pod_identity_association = true
  namespace                       = "kube-system"
  service_account                 = "karpenter"
}

moved {
  from = module.karpenter
  to   = module.karpenter[0]
}
