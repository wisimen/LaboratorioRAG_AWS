variable "master_instance_id" {
  description = "ID de la instancia master de K3S donde se ejecuta la verificacion"
  type        = string
}

variable "aws_region" {
  description = "Region AWS para ejecutar comandos SSM"
  type        = string
}

variable "n8n_url" {
  description = "URL interna a validar para n8n"
  type        = string
  default     = "http://127.0.0.1/n8n/"
}

variable "ollama_url" {
  description = "URL interna a validar para Ollama"
  type        = string
  default     = "http://127.0.0.1/ollama/api/tags"
}

variable "max_retries" {
  description = "Cantidad maxima de reintentos del check HTTP en la instancia"
  type        = number
  default     = 12
}

variable "retry_interval_seconds" {
  description = "Segundos de espera entre reintentos de verificacion"
  type        = number
  default     = 10
}

variable "command_poll_seconds" {
  description = "Segundos de espera entre consultas del estado del comando SSM"
  type        = number
  default     = 5
}

variable "command_timeout_seconds" {
  description = "Tiempo maximo total de espera del comando SSM en segundos"
  type        = number
  default     = 900
}

variable "n8n_association_id" {
  description = "Association ID de despliegue n8n para encadenar la verificacion"
  type        = string
}

variable "ollama_association_id" {
  description = "Association ID de despliegue ollama para encadenar la verificacion"
  type        = string
}
