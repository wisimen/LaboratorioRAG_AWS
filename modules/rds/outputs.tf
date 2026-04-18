output "db_instance_id" {
  description = "Identificador de la instancia RDS"
  value       = aws_db_instance.n8n_postgres.id
}

output "db_instance_endpoint" {
  description = "Endpoint de RDS (host:port)"
  value       = aws_db_instance.n8n_postgres.endpoint
}

output "db_instance_address" {
  description = "Dirección de host de RDS"
  value       = aws_db_instance.n8n_postgres.address
}

output "db_instance_port" {
  description = "Puerto de RDS"
  value       = aws_db_instance.n8n_postgres.port
}

output "db_instance_resource_id" {
  description = "Resource ID de RDS"
  value       = aws_db_instance.n8n_postgres.resource_id
}

output "db_name" {
  description = "Nombre de la base de datos"
  value       = aws_db_instance.n8n_postgres.db_name
}

output "db_username" {
  description = "Usuario administrativo"
  value       = aws_db_instance.n8n_postgres.username
}

output "db_connection_string" {
  description = "Connection string para n8n (PostgreSQL)"
  value       = "postgresql://${aws_db_instance.n8n_postgres.username}@${aws_db_instance.n8n_postgres.address}:${aws_db_instance.n8n_postgres.port}/${aws_db_instance.n8n_postgres.db_name}"
  sensitive   = true
}
