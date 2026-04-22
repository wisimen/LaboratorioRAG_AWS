variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de subnets donde se crean mount targets de EFS (una por AZ)"
  type        = list(string)
}

variable "efs_sg_id" {
  description = "Security Group para EFS"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
}