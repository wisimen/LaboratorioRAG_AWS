module "n8n" {
  source = "./n8n"

  master_instance_id      = var.master_instance_id
  aws_region              = var.aws_region
  namespace               = var.namespace
  db_host                 = var.n8n_db_host
  db_name                 = var.n8n_db_name
  db_user                 = var.n8n_db_user
  db_password             = var.n8n_db_password
  n8n_encryption_key      = var.n8n_encryption_key
  n8n_port                = var.n8n_port
  environment             = var.environment
  pvc_name                = var.pvc_name
}

module "ollama" {
  source = "./ollama"

  master_instance_id = var.master_instance_id
  aws_region         = var.aws_region
  namespace          = var.namespace
}

output "n8n_url" {
  description = "URL pública para acceder a n8n via nip.io"
  value       = "http://${var.k3s_master_public_ip}.nip.io/n8n/"
}

output "n8n_url_private" {
  description = "URL privada para acceder a n8n via ingress"
  value       = "http://${var.k3s_master_private_ip}/n8n/"
}

output "ollama_url" {
  description = "URL pública base para acceder a Ollama via ingress"
  value       = "http://${var.k3s_master_public_ip}/ollama"
}

output "ollama_url_private" {
  description = "URL privada base para acceder a Ollama via ingress"
  value       = "http://${var.k3s_master_private_ip}/ollama"
}
