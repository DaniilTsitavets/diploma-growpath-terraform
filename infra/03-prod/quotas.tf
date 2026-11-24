# New accounts start at 5 vCPU, which the two system nodes alone nearly use up.
resource "aws_servicequotas_service_quota" "on_demand_vcpus" {
  service_code = "ec2"
  quota_code   = "L-1216C47A"
  value        = var.ec2_vcpu_quota
}

resource "aws_servicequotas_service_quota" "spot_vcpus" {
  service_code = "ec2"
  quota_code   = "L-34B43A08"
  value        = var.ec2_vcpu_quota
}

# Karpenter fails its first Spot launch if the service-linked role does not exist yet.
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}
