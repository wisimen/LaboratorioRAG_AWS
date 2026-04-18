module "n8n" {
  source = "./n8n"

  master_instance_id = var.master_instance_id
  aws_region         = var.aws_region
  namespace          = var.namespace
  db_host            = var.n8n_db_host
  db_name            = var.n8n_db_name
  db_user            = var.n8n_db_user
  db_password        = var.n8n_db_password
}

module "ollama" {
  source = "./ollama"

  master_instance_id = var.master_instance_id
  aws_region         = var.aws_region
  namespace          = var.namespace
}

output "n8n_url" {
  description = "URL base para acceder a n8n via ingress"
  value       = "http://${var.k3s_master_private_ip}/n8n"
}

output "ollama_url" {
  description = "URL base para acceder a Ollama via ingress"
  value       = "http://${var.k3s_master_private_ip}/ollama"
}
