variable "master_instance_id" {
  description = "ID de la instancia master de K3S donde se aplicaran los manifiestos"
  type        = string
}

variable "k3s_master_public_ip" {
  description = "IP pública del master K3S usada como base del ingress"
  type        = string
}

variable "k3s_master_private_ip" {
  description = "IP privada del master K3S usada como base del ingress"
  type        = string
}

variable "aws_region" {
  description = "Region AWS para ejecutar comandos SSM"
  type        = string
}

variable "namespace" {
  description = "Namespace de despliegue"
  type        = string
  default     = "default"
}

variable "n8n_db_host" {
  description = "Host de PostgreSQL para n8n"
  type        = string
}

variable "n8n_db_name" {
  description = "Nombre de base de datos para n8n"
  type        = string
}

variable "n8n_db_user" {
  description = "Usuario de base de datos para n8n"
  type        = string
}

variable "n8n_db_password" {
  description = "Password de base de datos para n8n"
  type        = string
  sensitive   = true
}

variable "n8n_encryption_key" {
  description = "Clave de encriptación para n8n"
  type        = string
  sensitive   = true
}

variable "n8n_port" {
  description = "Puerto NodePort para n8n (rango 30000-32767)"
  type        = number
  default     = 30567
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "pvc_name" {
  description = "Nombre del PVC para persistencia de n8n"
  type        = string
  default     = "efs-pvc-shared"
}
