terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.17"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}