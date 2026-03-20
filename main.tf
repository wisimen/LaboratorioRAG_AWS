########## VPC ##########
# / -> VPC

resource "aws_vpc" "vpc-itm-rag-legal" {
  cidr_block           = var.vpc_cidr[terraform.workspace]
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc-itm-rag-legal"
    Environment = var.environment_name[terraform.workspace]
  }
}

########## Subnets ##########
# / -> VPC -> Subnet
# Subnet frontend publica
resource "aws_subnet" "subnet-public-frontend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_public_frontend_cidr_block[terraform.workspace]
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "Sub red de fontend publica"
    Environment = var.environment_name[terraform.workspace]
  }
}

########## Subnet 2 ##########
resource "aws_subnet" "subnet-private-frontend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_private_frontend_cidr_block[terraform.workspace]
  availability_zone       = var.aws_availability_zone_2
  map_public_ip_on_launch = false

  tags = {
    Name = "Sub red de fontend privada"
    Environment = var.environment_name[terraform.workspace]
  }
}

########## Subnet 3 ##########
resource "aws_subnet" "subnet-public-backend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_public_backend_cidr_block[terraform.workspace]
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "Sub red de backend publica"
    Environment = var.environment_name[terraform.workspace]
  }
}

########## Subnet 4 ##########
resource "aws_subnet" "subnet-private-backend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_private_backend_cidr_block[terraform.workspace]
  availability_zone       = var.aws_availability_zone_2
  map_public_ip_on_launch = false

  tags = {
    Name = "Sub red de backend privada"
    Environment = var.environment_name[terraform.workspace]
  }
}


############ Internet Gateway ##########
# / -> VPC -> Internet Gateway
resource "aws_internet_gateway" "igw-itm-rag-legal" {
  vpc_id = aws_vpc.vpc-itm-rag-legal.id
  tags = {
    Name = "Internet Gateway de itm rag legal"
    Environment = var.environment_name[terraform.workspace]
  }
}

############ Elastic IP para NAT Gateway ##########
# / -> VPC -> Elastic IP
resource "aws_eip" "eip-nat-gw" {
  domain = "vpc"
  
  tags = {
    Name        = "EIP para NAT Gateway"
    Environment = var.environment_name[terraform.workspace]
  }
}

############ NAT Gateway ##########
# / -> VPC -> Subnet Pública -> NAT Gateway
resource "aws_nat_gateway" "nat-gw-itm-rag-legal" {
  allocation_id = aws_eip.eip-nat-gw.id
  subnet_id     = aws_subnet.subnet-public-frontend.id # Se ubica en la red pública

  tags = {
    Name        = "NAT Gateway de itm rag legal"
    Environment = var.environment_name[terraform.workspace]
  }
  
  # Es buena práctica asegurar que el IGW exista antes de crear el NAT
  depends_on = [aws_internet_gateway.igw-itm-rag-legal]
}

############ Route Table PÚBLICA ##########
# / -> VPC -> Route Table (Pública)
resource "aws_route_table" "rtb-public-itm-rag-legal" {
  vpc_id = aws_vpc.vpc-itm-rag-legal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-itm-rag-legal.id
  }

  tags = {
    Name        = "Route Table Publica de itm rag legal"
    Environment = var.environment_name[terraform.workspace]
  }
}

############ Route Table PRIVADA ##########
# / -> VPC -> Route Table (Privada)
resource "aws_route_table" "rtb-private-itm-rag-legal" {
  vpc_id = aws_vpc.vpc-itm-rag-legal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw-itm-rag-legal.id # El tráfico sale por el NAT
  }

  tags = {
    Name        = "Route Table Privada de itm rag legal"
    Environment = var.environment_name[terraform.workspace]
  }
}

############ Route Table Associations ##########
# / -> VPC -> Subnet -> Route Table Association

# Asociaciones Públicas
resource "aws_route_table_association" "rta-public-frontend" {
  subnet_id      = aws_subnet.subnet-public-frontend.id
  route_table_id = aws_route_table.rtb-public-itm-rag-legal.id
}
resource "aws_route_table_association" "rta-public-backend" {
  subnet_id      = aws_subnet.subnet-public-backend.id
  route_table_id = aws_route_table.rtb-public-itm-rag-legal.id
}

# Asociaciones Privadas
resource "aws_route_table_association" "rta-private-frontend" {
  subnet_id      = aws_subnet.subnet-private-frontend.id
  route_table_id = aws_route_table.rtb-private-itm-rag-legal.id
}
resource "aws_route_table_association" "rta-private-backend" {
  subnet_id      = aws_subnet.subnet-private-backend.id
  route_table_id = aws_route_table.rtb-private-itm-rag-legal.id
}

##### Network ACL - Subnet Pública Frontend ####
# / -> VPC -> Subnet -> Network ACL
resource "aws_network_acl" "nacl-public-frontend" {
  vpc_id     = aws_vpc.vpc-itm-rag-legal.id
  subnet_ids = [ aws_subnet.subnet-public-frontend.id ]

  # ==========================================
  # REGLAS DE ENTRADA (INGRESS)
  # ==========================================

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Permite recibir la respuesta a las peticiones que el servidor inició hacia internet
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # ==========================================
  # REGLAS DE SALIDA (EGRESS)
  # ==========================================

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Permite devolver la página web a los usuarios que entraron por el puerto 80 o 443
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "ACL para subnet frontend publica"
    Environment = var.environment_name[terraform.workspace]
  }
}


##### Network ACL - Subnet Pública Backend ####
# / -> VPC -> Subnet -> Network ACL

resource "aws_network_acl" "nacl-public-backend" {
  vpc_id     = aws_vpc.vpc-itm-rag-legal.id
  subnet_ids = [ aws_subnet.subnet-public-backend.id ]

  # ================= INGRESS =================
  # 50: Confianza total a la red interna (VPC)
  ingress {
    protocol   = "-1"
    rule_no    = 50
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }
  # 100, 200, 300: Tráfico de internet (HTTP, HTTPS, Efímeros)
  ingress { 
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80 
  }

  ingress { 
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443 
  }

  ingress { 
    protocol = "tcp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535 
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # ================= EGRESS =================
  egress {
    protocol   = "-1"
    rule_no    = 50
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }
  egress { 
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80 
  }
  egress { 
    protocol = "tcp"
    rule_no = 200
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443 
  }
  egress { 
    protocol = "tcp"
    rule_no = 300
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535 
  }

  tags = {
    Name        = "ACL para subnet backend publica"
    Environment = var.environment_name[terraform.workspace]
  }
}


#### Network ACL - Subnet Privada Frontend ####
# / -> VPC -> Subnet -> Network ACL
resource "aws_network_acl" "nacl-private-frontend" {
  vpc_id     = aws_vpc.vpc-itm-rag-legal.id
  subnet_ids = [ aws_subnet.subnet-private-frontend.id ]

  # ================= INGRESS =================
  ingress { # 100: Confianza total a la red interna
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }
  
  ingress { # 200: Recibir descarga de internet (respuesta del NAT)
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # ================= EGRESS =================
  egress { # 100: Confianza total a la red interna
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }
  egress { # 200: Peticiones HTTP hacia internet (vía NAT)
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  egress { # 300: Peticiones HTTPS hacia internet (vía NAT)
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name        = "ACL para subnet frontend privada"
    Environment = var.environment_name[terraform.workspace]
  }
}

#### Network ACL - Subnet Privada Backend ####
# / -> VPC -> Subnet -> Network ACL
resource "aws_network_acl" "nacl-private-backend" {
  vpc_id     = aws_vpc.vpc-itm-rag-legal.id
  subnet_ids = [ aws_subnet.subnet-private-backend.id ]

  # ================= INGRESS =================
  ingress { # 100: Confianza total a la red interna
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress { # 200: Recibir descarga de internet (respuesta del NAT)
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # ================= EGRESS =================
  egress { # 100: Confianza total a la red interna
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }
  egress { # 200: Peticiones HTTP hacia internet (vía NAT)
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  egress { # 300: Peticiones HTTPS hacia internet (vía NAT)
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name        = "ACL para subnet backend privada"
    Environment = var.environment_name[terraform.workspace]
  }
}



########## Security Groups ##########
# / -> VPC -> Security Group

resource "aws_security_group" "secgroup-public-frontend" {
  name        = "secgroup-frontend-web"
  description = "Permite trafico HTTP, HTTPS y SSH"
  vpc_id      = aws_vpc.vpc-itm-rag-legal.id

  # Ingress: Tráfico entrante permitido
  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH desde Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Nota: En producción, cambia esto por tu IP real
  }

  # Egress: Tráfico saliente permitido (Stateful: permite todo hacia afuera)
  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 significa todos los protocolos
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SG Frontend Publico"
    Environment = var.environment_name[terraform.workspace]
  }
}

########## Data Source: AMI ##########
# Busca la última AMI de Amazon Linux 2023

/*
Búsqueda de la AMI de Amazon Linux 2023
Para levantar la instancia, necesitamos una "Imagen" (AMI). 
Es buena práctica usar un bloque data para que Terraform busque
automáticamente la última versión de Amazon Linux, en lugar de
poner un ID fijo que se volverá obsoleto rápidamente.
*/

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}


########## EC2 Instance ##########
# / -> VPC -> Subnet Pública -> EC2

resource "aws_instance" "web_frontend" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.subnet-public-frontend.id
  vpc_security_group_ids      = [aws_security_group.secgroup-public-frontend.id]
  associate_public_ip_address = true # Aseguramos que tenga IP pública para ver la web

  # Script de inicio (User Data)
  user_data = <<-EOF
              #!/bin/bash
              # Actualizar paquetes
              dnf update -y
              
              # Instalar servidor web Apache
              dnf install -y httpd
              
              # Iniciar el servicio y asegurar que arranque al reiniciar
              systemctl start httpd
              systemctl enable httpd
              
              # Crear la página de Hola Mundo
              echo "<h1>Hola Mundo desde mi Frontend en AWS! 🚀</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name        = "EC2 Frontend Web"
    Environment = var.environment_name[terraform.workspace]
  }
}

########## Outputs ##########
# Muestra la IP pública en la consola al terminar el 'terraform apply'

output "frontend_public_ip" {
  description = "La IP publica de la instancia EC2 Frontend"
  value       = aws_instance.web_frontend.public_ip
}

output "frontend_url" {
  description = "URL para acceder al servidor web"
  value       = "http://${aws_instance.web_frontend.public_ip}"
}


########## Módulo K3S ##########
# Despliega un cluster Kubernetes ligero (k3s) con un Master y un Worker en t3.micro.
# Los nodos se ubican en la subnet PRIVADA; el acceso de administración se realiza
# exclusivamente vía SSM Session Manager (sin SSH, sin IP pública).
# Incluye un bucket S3 y un EFS para el almacenamiento persistente de los pods.

module "k3s" {
  source = "./modules/k3s"

  vpc_id      = aws_vpc.vpc-itm-rag-legal.id
  vpc_cidr    = var.vpc_cidr[terraform.workspace]
  subnet_id   = aws_subnet.subnet-private-backend.id
  environment = var.environment_name[terraform.workspace]
  ami_id      = data.aws_ami.amazon_linux_2023.id
  aws_region  = var.aws_region
}

output "k3s_master_instance_id" {
  description = "ID de la instancia Master K3S (usar con SSM Session Manager)"
  value       = module.k3s.master_instance_id
}

output "k3s_worker_instance_id" {
  description = "ID de la instancia Worker K3S (usar con SSM Session Manager)"
  value       = module.k3s.worker_instance_id
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
  value       = module.k3s.efs_dns_name
}