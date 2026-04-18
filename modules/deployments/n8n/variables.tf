variable "master_instance_id" {
  description = "ID de la instancia master de K3S"
  type        = string
}

variable "aws_region" {
  description = "Region AWS para SSM"
  type        = string
}

variable "namespace" {
  description = "Namespace Kubernetes"
  type        = string
}

variable "db_host" {
  description = "Host de PostgreSQL"
  type        = string
}

variable "db_name" {
  description = "Nombre de DB"
  type        = string
}

variable "db_user" {
  description = "Usuario DB"
  type        = string
}

variable "db_password" {
  description = "Password DB"
  type        = string
  sensitive   = true
}
