########## Módulo Networking ##########
# Contiene VPC, subnets, IGW, NAT, route tables, NACLs y SGs.

module "networking" {
  source = "./modules/networking"

  vpc_cidr                           = var.vpc_cidr[terraform.workspace]
  subnet_public_frontend_cidr_block  = var.subnet_public_frontend_cidr_block[terraform.workspace]
  subnet_private_frontend_cidr_block = var.subnet_private_frontend_cidr_block[terraform.workspace]
  subnet_public_backend_cidr_block   = var.subnet_public_backend_cidr_block[terraform.workspace]
  subnet_private_backend_cidr_block  = var.subnet_private_backend_cidr_block[terraform.workspace]
  aws_availability_zone_1            = var.aws_availability_zone_1
  aws_availability_zone_2            = var.aws_availability_zone_2
  environment                        = var.environment_name[terraform.workspace]
  aws_region                         = var.aws_region
  admin_ip                           = var.admin_ip
}

########## Data Source: AMI ##########
# Busca la última AMI de Amazon Linux 2023

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

########## Módulo EC2 ##########

module "ec2" {
  source = "./modules/ec2"

  ami_id                      = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.small"
  subnet_id                   = module.networking.subnet_public_frontend_id
  security_group_ids          = [module.networking.secgroup_public_frontend_id]
  associate_public_ip_address = true
  environment                 = var.environment_name[terraform.workspace]
}

########## Outputs ##########

output "frontend_public_ip" {
  description = "La IP publica de la instancia EC2 Frontend"
  value       = module.ec2.public_ip
}

output "frontend_url" {
  description = "URL para acceder al servidor web"
  value       = module.ec2.public_url
}

########## Módulo Storage ##########

module "storage" {
  source = "./modules/storage"

  vpc_id      = module.networking.vpc_id
  subnet_ids  = [module.networking.subnet_public_backend_id, module.networking.subnet_private_backend_id]
  efs_sg_id   = module.networking.efs_sg_id
  environment = var.environment_name[terraform.workspace]
}

moved {
  from = module.k3s.aws_security_group.secgroup-k3s-ssm-endpoints
  to   = module.networking.aws_security_group.secgroup-k3s-ssm-endpoints
}

moved {
  from = module.k3s.aws_vpc_endpoint.ssm
  to   = module.networking.aws_vpc_endpoint.ssm
}

moved {
  from = module.k3s.aws_vpc_endpoint.ssmmessages
  to   = module.networking.aws_vpc_endpoint.ssmmessages
}

moved {
  from = module.k3s.aws_vpc_endpoint.ec2messages
  to   = module.networking.aws_vpc_endpoint.ec2messages
}

########## Módulo RDS ##########

module "rds" {
  source = "./modules/rds"

  engine                   = var.rds_engine[terraform.workspace]
  engine_version           = var.rds_engine_version[terraform.workspace]
  instance_class           = var.rds_instance_class[terraform.workspace]
  allocated_storage        = var.rds_allocated_storage[terraform.workspace]
  db_name                  = var.rds_db_name[terraform.workspace]
  username                 = var.rds_username[terraform.workspace]
  password                 = var.rds_password[terraform.workspace]
  db_subnet_group_name     = module.networking.rds_subnet_group_name
  vpc_security_group_ids   = module.networking.rds_sg_id
  skip_final_snapshot      = var.rds_skip_final_snapshot[terraform.workspace]
  environment              = var.environment_name[terraform.workspace]

  depends_on = [module.networking, module.storage]
}

########## Módulo K3S ##########

module "k3s" {
  source = "./modules/k3s"

  vpc_id      = module.networking.vpc_id
  vpc_cidr    = module.networking.vpc_cidr
  master_subnet_id = module.networking.subnet_public_backend_id
  worker_subnet_id = module.networking.subnet_private_backend_id
  environment = var.environment_name[terraform.workspace]
  ami_id      = data.aws_ami.amazon_linux_2023.id
  aws_region  = var.aws_region
  efs_id      = module.storage.efs_id
  k3s_security_group_id = module.networking.k3s_security_group_id
  root_volume_size_gb = var.k3s_root_volume_size_gb
}

########## Módulo Deployments (n8n + ollama) ##########

module "deployments" {
  source = "./modules/deployments"

  master_instance_id    = module.k3s.master_instance_id
  k3s_master_public_ip  = module.k3s.master_public_ip
  k3s_master_private_ip = module.k3s.master_private_ip
  aws_region            = var.aws_region
  namespace             = "default"
  n8n_db_host           = module.rds.db_instance_address
  n8n_db_name           = module.rds.db_name
  n8n_db_user           = module.rds.db_username
  n8n_db_password       = var.rds_password[terraform.workspace]

  depends_on = [module.k3s, module.rds]
}

########## Módulo Verify (health checks n8n + ollama) ##########

module "verify" {
  source = "./modules/verify"

  master_instance_id    = module.k3s.master_instance_id
  aws_region            = var.aws_region
  n8n_association_id    = module.deployments.n8n_association_id
  ollama_association_id = module.deployments.ollama_association_id

  depends_on = [module.deployments]
}

output "k3s_master_instance_id" {
  description = "ID de la instancia Master K3S (usar con SSM Session Manager)"
  value       = module.k3s.master_instance_id
}

output "k3s_master_public_ip" {
  description = "IP pública del Master K3S"
  value       = module.k3s.master_public_ip
}

output "k3s_master_private_ip" {
  description = "IP privada del Master K3S"
  value       = module.k3s.master_private_ip
}

output "k3s_worker_instance_id" {
  description = "ID de la instancia Worker K3S (usar con SSM Session Manager)"
  value       = module.k3s.worker_instance_id
}

output "k3s_worker_public_ip" {
  description = "IP pública del Worker K3S"
  value       = module.k3s.worker_public_ip
}

output "k3s_ssm_connect_master" {
  description = "Comando SSM Session Manager para acceder al Master K3S"
  value       = module.k3s.ssm_connect_master
}

output "k3s_ssm_connect_worker" {
  description = "Comando SSM Session Manager para acceder al Worker K3S"
  value       = module.k3s.ssm_connect_worker
}

output "k3s_kubectl_port_forward" {
  description = "Comando para port-forward del API Server K3S vía SSM"
  value       = module.k3s.kubectl_port_forward
}

output "k3s_s3_bucket" {
  description = "Nombre del bucket S3 del cluster K3S"
  value       = module.k3s.s3_bucket_name
}

output "k3s_efs_dns" {
  description = "DNS del EFS para volúmenes persistentes del cluster K3S"
  value       = module.storage.efs_dns_name
}

########## Outputs - RDS ##########

output "rds_endpoint" {
  description = "Endpoint de RDS (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_address" {
  description = "Dirección de host de RDS para n8n"
  value       = module.rds.db_instance_address
}

output "rds_port" {
  description = "Puerto de RDS"
  value       = module.rds.db_instance_port
}

output "rds_db_name" {
  description = "Nombre de la base de datos RDS"
  value       = module.rds.db_name
}

output "rds_username" {
  description = "Usuario administrativo de RDS"
  value       = module.rds.db_username
}

output "rds_connection_string" {
  description = "Connection string para n8n (PostgreSQL) - SENSIBLE"
  value       = module.rds.db_connection_string
  sensitive   = true
}

########## Outputs - Deployments ##########

output "deploy_n8n_association_id" {
  description = "ID de la asociacion SSM que despliega n8n"
  value       = module.deployments.n8n_association_id
}

output "deploy_ollama_association_id" {
  description = "ID de la asociacion SSM que despliega ollama"
  value       = module.deployments.ollama_association_id
}

output "deploy_n8n_url" {
  description = "URL pública base para acceder a n8n via ingress"
  value       = module.deployments.n8n_url
}

output "deploy_n8n_url_private" {
  description = "URL privada base para acceder a n8n via ingress"
  value       = module.deployments.n8n_url_private
}

output "deploy_ollama_url" {
  description = "URL pública base para acceder a Ollama via ingress"
  value       = module.deployments.ollama_url
}

output "deploy_ollama_url_private" {
  description = "URL privada base para acceder a Ollama via ingress"
  value       = module.deployments.ollama_url_private
}

output "verify_id" {
  description = "ID interno de la verificacion post-deploy"
  value       = module.verify.verification_id
}
