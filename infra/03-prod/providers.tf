terraform {
  required_version = ">= 1.11.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
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

provider "aws" {
  alias  = "dns"
  region = var.region

  assume_role {
    role_arn = var.dns_role_arn
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
