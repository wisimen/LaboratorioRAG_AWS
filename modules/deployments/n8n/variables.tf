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

variable "environment" {
  description = "Ambiente (dev, staging, prod, etc)"
  type        = string
}

variable "aws_region" {
  description = "Region AWS para SSM"
  type        = string
}

variable "n8n_port" {
  description = "Puerto NodePort para n8n (rango 30000-32767)"
  type        = number
  default     = 30567
}

variable "n8n_encryption_key" {
  description = "Clave de encriptación para n8n"
  type        = string
  sensitive   = true
}

variable "pvc_name" {
  description = "Nombre del PVC para persistencia de n8n"
  type        = string
  default     = "efs-pvc-shared"
}
