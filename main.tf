########## VPC ##########

resource "aws_vpc" "RagVpc1" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "RagVpc1"

  }
}

########## Subnets ##########