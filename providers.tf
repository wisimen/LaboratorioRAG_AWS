terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Estado remoto en S3 — compartido entre todos los miembros del equipo.
  # El bucket "ws-base-bucket" debe existir previamente en la cuenta AWS.
  # Cada workspace escribe su estado en una key distinta gracias al prefijo
  # automático que Terraform añade cuando se usa workspaces con backend S3:
  #   env:/<workspace>/itm_iac_state.tfstate
  backend "s3" {
    bucket  = "ws-base-bucket"
    key     = "itm_iac_state.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Configure and downloading plugins for aws
provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
}