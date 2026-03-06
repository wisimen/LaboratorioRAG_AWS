terraform {
  required_providers {
    aws={
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
  }
  backend "local" {
    path = "./state/itm_iac_state.tfstate"
  }
}

# Configure and downloading plugins for aws
provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
}