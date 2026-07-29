terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = local.etiquettes
  }
}

locals {
  prefixe = "tpiac-dev"
  etiquettes = {
    Projet      = "tp-iac"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "ymaincent"
  }
}
