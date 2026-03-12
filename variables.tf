# Region
variable "aws_region" {
  default = "us-east-1"
}

# Profile
variable "aws_profile" {
  default = "default"
}

# Availability Zones
variable "aws_availability_zone_1" {
  default = "us-east-1a"
}

# Availability Zones
variable "aws_availability_zone_2" {
  default = "us-east-1b"
}

# VPC CIDR Block
variable "vpc_cidr" {
  type = map(string)
  default = {
    "default" = "216.216.0.0/22",
    "prod" = "216.216.0.0/22",
    "test" = "217.217.0.0/22",
    "dev" = "218.218.0.0/22"
  }
}

# Subnet frontend - publico 
variable "subnet_public_frontend_cidr_block" {
    description = "La Ip de la subred para el frontend"
    type = map(string)
    default = {
      "default" = "216.216.0.0/24",
      "prod" = "216.216.0.0/24",
      "test" = "217.217.0.0/24",
      "dev" = "218.218.0.0/24"
    }
}
# Subnet frontend - privado 
variable "subnet_private_frontend_cidr_block" {
    description = "La Ip de la subred para el frontend"
    type = map(string)
    default = {
      "default" = "216.216.1.0/24",
      "prod" = "216.216.1.0/24",
      "test" = "217.217.1.0/24",
      "dev" = "218.218.1.0/24"
    }
}

# Subnet backend - publico
variable "subnet_public_backend_cidr_block" {
    description = "La Ip de la subred para el backend"
    type = map(string)
    default = {
      "default" = "216.216.2.0/24",
      "prod" = "216.216.2.0/24",
      "test" = "217.217.2.0/24",
      "dev" = "218.218.2.0/24"
    }
}
# Subnet backend - privado
variable "subnet_private_backend_cidr_block" {
    description = "La Ip de la subred para el backend"
    type = map(string)
    default = {
      "default" = "216.216.3.0/24",
      "prod" = "216.216.3.0/24",
      "test" = "217.217.3.0/24",
      "dev" = "218.218.3.0/24"
    }
} 


###### ACL Network ######
variable "acl_network_name" {
  description = "The name for the Network ACL"
  type        = map(string)
  default = {
    "default" = "ACL-ITMPruebas",
    "prod"    = "ACL-ITMProd",
    "test"    = "ACL-ITMTest",
    "dev"     = "ACL-ITMDev"
  }
}

###### Route Table ######
variable "route_table_cidr_block" {
  description = "The CIDR block for the route table"
  type        = map(string)
  default = {
    "default" = "0.0.0.0/0",
    "prod"    = "0.0.0.0/0",
    "test"    = "0.0.0.0/0",
    "dev"     = "0.0.0.0/0"
  }
}
