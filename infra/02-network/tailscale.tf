resource "aws_ssm_parameter" "tailscale_auth_key" {
  name        = "/growpath/tailscale/auth-key"
  description = "Tailscale auth key of the subnet router, replace the placeholder in the console"
  type        = "SecureString"
  value       = "CHANGE_ME"

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_iam_policy_document" "tailscale_read_key" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.tailscale_auth_key.arn]
  }
}

resource "aws_iam_policy" "tailscale_read_key" {
  name   = "tailscale-router-read-auth-key"
  policy = data.aws_iam_policy_document.tailscale_read_key.json
}

module "tailscale_router" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.4"

  name              = "tailscale-router"
  instance_type     = var.tailscale_instance_type
  ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"

  subnet_id                   = module.vpc.private_subnets[0]
  associate_public_ip_address = false
  source_dest_check           = false

  create_security_group = true
  security_group_vpc_id = module.vpc.vpc_id

  create_iam_instance_profile = true
  iam_role_policies = {
    SSMCore     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ReadAuthKey = aws_iam_policy.tailscale_read_key.arn
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device = {
    encrypted = true
    type      = "gp3"
    size      = 8
  }

  user_data = templatefile("${path.module}/tailscale-user-data.sh.tftpl", {
    auth_key_parameter = aws_ssm_parameter.tailscale_auth_key.name
    vpc_cidr           = var.vpc_cidr
    region             = var.region
  })
  user_data_replace_on_change = true
}
