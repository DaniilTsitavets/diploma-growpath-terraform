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
      Project     = "growpath"
      Layer       = "03-prod"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "network"
  region = var.region

  assume_role {
    role_arn = var.network_role_arn
  }

  default_tags {
    tags = {
      Project     = "growpath"
      Layer       = "03-prod"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
