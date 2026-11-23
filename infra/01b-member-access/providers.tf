terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "growpath"
      Layer     = "01b-member-access"
      ManagedBy = "terraform"
    }
  }
}

provider "aws" {
  alias  = "network"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["network"]}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Project   = "growpath"
      Layer     = "01b-member-access"
      ManagedBy = "terraform"
    }
  }
}

provider "aws" {
  alias  = "prod"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["prod"]}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      Project   = "growpath"
      Layer     = "01b-member-access"
      ManagedBy = "terraform"
    }
  }
}
