module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.11"

  name            = "${var.cluster_name}-aws-load-balancer-controller"
  use_name_prefix = false

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.11"

  name            = "${var.cluster_name}-ebs-csi"
  use_name_prefix = false

  attach_aws_ebs_csi_policy = true
}
