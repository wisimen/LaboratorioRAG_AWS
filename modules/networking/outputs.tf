output "vpc_id" {
  description = "ID del VPC"
  value       = aws_vpc.vpc-itm-rag-legal.id
}

output "vpc_cidr" {
  description = "CIDR del VPC"
  value       = aws_vpc.vpc-itm-rag-legal.cidr_block
}

output "subnet_public_frontend_id" {
  description = "ID de la subnet publica frontend"
  value       = aws_subnet.subnet-public-frontend.id
}

output "subnet_private_frontend_id" {
  description = "ID de la subnet privada frontend"
  value       = aws_subnet.subnet-private-frontend.id
}

output "subnet_public_backend_id" {
  description = "ID de la subnet publica backend"
  value       = aws_subnet.subnet-public-backend.id
}

output "subnet_private_backend_id" {
  description = "ID de la subnet privada backend"
  value       = aws_subnet.subnet-private-backend.id
}

output "secgroup_public_frontend_id" {
  description = "ID del security group publico frontend"
  value       = aws_security_group.secgroup-public-frontend.id
}

output "efs_sg_id" {
  description = "ID del security group para EFS"
  value       = aws_security_group.efs_sg.id
}

output "rds_sg_id" {
  description = "ID del security group para RDS"
  value       = aws_security_group.rds_sg.id
}

output "rds_subnet_group_name" {
  description = "Nombre del DB subnet group para RDS"
  value       = aws_db_subnet_group.rds_subnet_group.name
}
