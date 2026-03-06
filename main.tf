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

########## Subnet 1 ##########
resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.RagVpc1.id
  cidr_block              = var.subnet_1_cidr
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-1"
  }
}

########## Subnet 2 ##########
resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.RagVpc1.id
  cidr_block              = var.subnet_2_cidr
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-1"
  }
}