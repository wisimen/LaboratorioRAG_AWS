variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "subnet_id" {
  description = "Subnet privada donde se crea el mount target"
  type        = string
}

variable "efs_sg_id" {
  description = "Security Group para EFS"
  type        = string
}

variable "availability_az" {
  description = "AZ para EFS One Zone"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
}