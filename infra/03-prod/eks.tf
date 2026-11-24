data "aws_iam_roles" "sso_admin" {
  name_regex  = "^AWSReservedSSO_AdministratorAccess_"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.30"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access  = false
  endpoint_private_access = true

  enable_irsa                              = false
  enable_cluster_creator_admin_permissions = true

  # Standard support avoids the extended-support surcharge when the version ages out.
  upgrade_policy = {
    support_type = "STANDARD"
  }

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 7

  access_entries = {
    sso_admin = {
      # The access entry principal must not contain the reserved SSO path.
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${tolist(data.aws_iam_roles.sso_admin.names)[0]}"
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # kubectl and Argo CD reach the private endpoint through the Tailscale router.
  security_group_additional_rules = {
    tailscale_router = {
      description = "API server from the Tailscale router"
      from_port   = 443
      to_port     = 443
      cidr_blocks = [local.network_vpc_cidr]
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  addons = {
    eks-pod-identity-agent = {
      before_compute = true
    }
    vpc-cni = {
      before_compute = true
      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    kube-proxy = {}
    coredns    = {}
    aws-ebs-csi-driver = {
      pod_identity_association = [{
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }

  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.medium"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = {
        "karpenter.sh/controller" = "true"
      }

      taints = {
        critical_addons = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      # Prefix delegation lifts the per-node pod limit, but kubelet only uses it when told to.
      cloudinit_pre_nodeadm = [{
        content_type = "application/node.eks.aws"
        content      = <<-EOT
          ---
          apiVersion: node.eks.aws/v1alpha1
          kind: NodeConfig
          spec:
            kubelet:
              config:
                maxPods: 110
        EOT
      }]
    }
  }
}
