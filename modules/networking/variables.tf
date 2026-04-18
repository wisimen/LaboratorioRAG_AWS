variable "vpc_cidr" {
  description = "CIDR del VPC"
  type        = string
}

variable "subnet_public_frontend_cidr_block" {
  description = "CIDR de la subnet publica frontend"
  type        = string
}

variable "subnet_private_frontend_cidr_block" {
  description = "CIDR de la subnet privada frontend"
  type        = string
}

variable "subnet_public_backend_cidr_block" {
  description = "CIDR de la subnet publica backend"
  type        = string
}

variable "subnet_private_backend_cidr_block" {
  description = "CIDR de la subnet privada backend"
  type        = string
}

variable "aws_availability_zone_1" {
  description = "Availability Zone 1"
  type        = string
}

variable "aws_availability_zone_2" {
  description = "Availability Zone 2"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
}
