########## Variables - Módulo K3S ##########

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el cluster K3S"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet donde se desplegarán las instancias K3S"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block de la VPC para las reglas del Security Group"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, test, prod…)"
  type        = string
}

variable "ami_id" {
  description = "AMI ID para las instancias EC2 del cluster K3S"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS donde se desplegará el cluster"
  type        = string
  default     = "us-east-1"
}
