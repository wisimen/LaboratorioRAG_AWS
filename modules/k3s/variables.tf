########## Variables - Módulo K3S ##########

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el cluster K3S"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet PRIVADA donde se desplegarán las instancias K3S y los VPC Endpoints"
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

variable "k3s_version" {
  description = "Versión de k3s a instalar (e.g. v1.31.4+k3s1). Fijar a una versión concreta para reproducibilidad."
  type        = string
  default     = "v1.31.4+k3s1"
}

variable "aws_region" {
  description = "Región de AWS donde se desplegará el cluster"
  type        = string
  default     = "us-east-1"
}

variable "efs_id" {
  description = "ID del EFS creado por el módulo storage"
  type        = string
}