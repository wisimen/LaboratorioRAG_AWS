output "association_id" {
  description = "ID de la asociacion SSM para n8n"
  value       = aws_ssm_association.deploy_n8n.id
}
