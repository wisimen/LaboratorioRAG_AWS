# Region
variable "aws_region" {
  default = "us-east-1"
}

# Availability Zones
variable "aws_availability_zone_1" {
  default = "us-east-1a"
}

variable "aws_availability_zone_2" {
  default = "us-east-1d"
}

# Profile
variable "aws_profile" {
  default = "VSeminario"
}

# VPC CIDR Block
variable "vpc_cidr" {
  default = "192.168.7.0/24"
}

# Subnet 1 CIDR Block
variable "subnet_1_cidr" {
  default = "192.168.7.0/25"
}