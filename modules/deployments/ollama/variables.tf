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
