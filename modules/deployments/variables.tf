variable "master_instance_id" {
  description = "ID de la instancia master de K3S donde se aplicaran los manifiestos"
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
