########## Variables - Módulo K3S ##########

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el cluster K3S"
  type        = string
}

variable "master_subnet_id" {
  description = "ID de la subnet donde se desplegará el nodo Master K3S"
  type        = string
}

variable "worker_subnet_id" {
  description = "ID de la subnet PRIVADA donde se desplegará el nodo Worker K3S"
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

variable "k3s_security_group_id" {
  description = "ID del security group del cluster K3S creado en networking"
  type        = string
}

variable "root_volume_size_gb" {
  description = "Tamaño del volumen raíz EBS en GB para nodos K3S"
  type        = number
  default     = 80
}

variable "pv_name" {
  description = "Nombre del PersistentVolume para almacenamiento compartido"
  type        = string
  default     = "efs-pv-shared"
}

variable "pvc_name" {
  description = "Nombre del PersistentVolumeClaim para almacenamiento compartido"
  type        = string
  default     = "efs-pvc-shared"
}