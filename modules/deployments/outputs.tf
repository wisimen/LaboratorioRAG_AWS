output "n8n_association_id" {
  description = "Association ID SSM para despliegue de n8n"
  value       = module.n8n.association_id
}

output "ollama_association_id" {
  description = "Association ID SSM para despliegue de ollama"
  value       = module.ollama.association_id
}
