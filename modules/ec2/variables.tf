variable "ami_id" {
  description = "AMI para la instancia EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.small"
}

variable "subnet_id" {
  description = "ID de la subnet donde se despliega la EC2"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de IDs de security groups para la instancia"
  type        = list(string)
}

variable "associate_public_ip_address" {
  description = "Asociar IP publica a la instancia"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
}
