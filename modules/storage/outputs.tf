output "efs_id" {
  description = "ID del sistema de archivos EFS One Zone"
  value       = aws_efs_file_system.k3s_storage_efs.id
}

output "efs_dns_name" {
  description = "DNS del EFS One Zone"
  value       = aws_efs_file_system.k3s_storage_efs.dns_name
}