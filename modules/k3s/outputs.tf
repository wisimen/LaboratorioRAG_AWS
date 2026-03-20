########## Outputs - Módulo K3S ##########

output "master_public_ip" {
  description = "IP pública del nodo Master K3S"
  value       = aws_instance.k3s-master.public_ip
}

output "master_private_ip" {
  description = "IP privada del nodo Master K3S"
  value       = aws_instance.k3s-master.private_ip
}

output "worker_public_ip" {
  description = "IP pública del nodo Worker K3S"
  value       = aws_instance.k3s-worker.public_ip
}

output "worker_private_ip" {
  description = "IP privada del nodo Worker K3S"
  value       = aws_instance.k3s-worker.private_ip
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 para almacenamiento de objetos de los pods"
  value       = aws_s3_bucket.k3s-storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.k3s-storage.arn
}

output "efs_id" {
  description = "ID del sistema de archivos EFS para volúmenes persistentes"
  value       = aws_efs_file_system.k3s-efs.id
}

output "efs_dns_name" {
  description = "Nombre DNS del EFS para montar en los pods (Persistent Volumes)"
  value       = aws_efs_file_system.k3s-efs.dns_name
}

output "kubeconfig_command" {
  description = "Comando para obtener el kubeconfig desde el Master (via SSM Session Manager)"
  value       = "aws ssm start-session --target ${aws_instance.k3s-master.id} --region ${var.aws_region}"
}
