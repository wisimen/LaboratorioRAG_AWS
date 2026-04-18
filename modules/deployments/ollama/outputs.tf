output "association_id" {
  description = "ID de la asociacion SSM para ollama"
  value       = aws_ssm_association.deploy_ollama.id
}
