variable "engine" {
  description = "Motor de base de datos (postgres)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Versión del motor"
  type        = string
  default     = "17.6"
}

variable "instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Almacenamiento asignado (GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "n8ndb"
}

variable "username" {
  description = "Usuario administrativo de RDS"
  type        = string
  default     = "n8nadmin"
}

variable "password" {
  description = "Contraseña del usuario administrativo"
  type        = string
  sensitive   = true
}

variable "db_subnet_group_name" {
  description = "Nombre del DB subnet group"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "ID del security group para RDS"
  type        = string
}

variable "source_security_group_id" {
  description = "ID del security group origen (para K3S)"
  type        = string
}

variable "skip_final_snapshot" {
  description = "Si true, no crea snapshot final al destruir"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
}
