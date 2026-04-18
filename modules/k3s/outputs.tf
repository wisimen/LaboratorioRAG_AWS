########## Outputs - Módulo K3S ##########
# Los nodos están en una subnet PRIVADA; no tienen IP pública.
# Acceso de administración exclusivamente vía SSM Session Manager.

output "master_instance_id" {
  description = "ID de la instancia EC2 del nodo Master K3S"
  value       = aws_instance.k3s-master.id
}

output "master_private_ip" {
  description = "IP privada del nodo Master K3S"
  value       = aws_instance.k3s-master.private_ip
}

output "master_public_ip" {
  description = "IP pública del nodo Master K3S"
  value       = aws_instance.k3s-master.public_ip
}

output "worker_instance_id" {
  description = "ID de la instancia EC2 del nodo Worker K3S"
  value       = aws_instance.k3s-worker.id
}

output "worker_private_ip" {
  description = "IP privada del nodo Worker K3S"
  value       = aws_instance.k3s-worker.private_ip
}

output "worker_public_ip" {
  description = "IP pública del nodo Worker K3S"
  value       = aws_instance.k3s-worker.public_ip
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3 para almacenamiento de objetos de los pods"
  value       = aws_s3_bucket.k3s-storage.bucket
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.k3s-storage.arn
}

output "ssm_connect_master" {
  description = "Comando SSM Session Manager para conectarse al nodo Master"
  value       = "aws ssm start-session --target ${aws_instance.k3s-master.id} --region ${var.aws_region}"
}

output "ssm_connect_worker" {
  description = "Comando SSM Session Manager para conectarse al nodo Worker"
  value       = "aws ssm start-session --target ${aws_instance.k3s-worker.id} --region ${var.aws_region}"
}

output "kubectl_port_forward" {
  description = "Comando para hacer port-forward del API Server K3S vía SSM (requiere plugin session-manager-plugin)"
  value       = "aws ssm start-session --target ${aws_instance.k3s-master.id} --region ${var.aws_region} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"6443\"],\"localPortNumber\":[\"6443\"]}'"
}

output "k3s_security_group_id" {
  description = "ID del security group del cluster K3S"
  value       = aws_security_group.secgroup-cluster-k3s.id
}
