########## VPC ##########
resource "aws_vpc" "vpc-itm-rag-legal" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "vpc-itm-rag-legal"
    Environment = var.environment
  }
}

########## Subnets ##########
resource "aws_subnet" "subnet-public-frontend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_public_frontend_cidr_block
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name        = "Sub red de fontend publica"
    Environment = var.environment
  }
}

resource "aws_subnet" "subnet-private-frontend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_private_frontend_cidr_block
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = false

  tags = {
    Name        = "Sub red de fontend privada"
    Environment = var.environment
  }
}

resource "aws_subnet" "subnet-public-backend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_public_backend_cidr_block
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name        = "Sub red de backend publica"
    Environment = var.environment
  }
}

resource "aws_subnet" "subnet-private-backend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_private_backend_cidr_block
  availability_zone       = var.aws_availability_zone_2
  map_public_ip_on_launch = false

  tags = {
    Name        = "Sub red de backend privada"
    Environment = var.environment
  }
}

############ Internet Gateway ##########
resource "aws_internet_gateway" "igw-itm-rag-legal" {
  vpc_id = aws_vpc.vpc-itm-rag-legal.id
  tags = {
    Name        = "Internet Gateway de itm rag legal"
    Environment = var.environment
  }
}

############ Elastic IP para NAT Gateway ##########
resource "aws_eip" "eip-nat-gw" {
  domain = "vpc"

  tags = {
    Name        = "EIP para NAT Gateway"
    Environment = var.environment
  }
}

############ NAT Gateway ##########
resource "aws_nat_gateway" "nat-gw-itm-rag-legal" {
  allocation_id = aws_eip.eip-nat-gw.id
  subnet_id     = aws_subnet.subnet-public-frontend.id

  tags = {
    Name        = "NAT Gateway de itm rag legal"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.igw-itm-rag-legal]
}

############ Route Table PÚBLICA ##########
resource "aws_route_table" "rtb-public-itm-rag-legal" {
  vpc_id = aws_vpc.vpc-itm-rag-legal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-itm-rag-legal.id
  }

  tags = {
    Name        = "Route Table Publica de itm rag legal"
    Environment = var.environment
  }
}

############ Route Table PRIVADA ##########
resource "aws_route_table" "rtb-private-itm-rag-legal" {
  vpc_id = aws_vpc.vpc-itm-rag-legal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw-itm-rag-legal.id
  }

  tags = {
    Name        = "Route Table Privada de itm rag legal"
    Environment = var.environment
  }
}

############ Route Table Associations ##########
resource "aws_route_table_association" "rta-public-frontend" {
  subnet_id      = aws_subnet.subnet-public-frontend.id
  route_table_id = aws_route_table.rtb-public-itm-rag-legal.id
}

resource "aws_route_table_association" "rta-public-backend" {
  subnet_id      = aws_subnet.subnet-public-backend.id
  route_table_id = aws_route_table.rtb-public-itm-rag-legal.id
}

resource "aws_route_table_association" "rta-private-frontend" {
  subnet_id      = aws_subnet.subnet-private-frontend.id
  route_table_id = aws_route_table.rtb-private-itm-rag-legal.id
}

resource "aws_route_table_association" "rta-private-backend" {
  subnet_id      = aws_subnet.subnet-private-backend.id
  route_table_id = aws_route_table.rtb-private-itm-rag-legal.id
}

##### Network ACL - Subnet Pública Frontend ####
resource "aws_network_acl" "nacl-public-frontend" {
  vpc_id     = aws_vpc.vpc-itm-rag-legal.id
  subnet_ids = [aws_subnet.subnet-public-frontend.id]

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
    Environment = var.environment
  }
}

##### Network ACL - Subnet Pública Backend ####
resource "aws_network_acl" "nacl-public-backend" {
  vpc_id     = aws_vpc.vpc-itm-rag-legal.id
  subnet_ids = [aws_subnet.subnet-public-backend.id]

  ingress {
    protocol   = "-1"
    rule_no    = 50
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }

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

  egress {
    protocol   = "-1"
    rule_no    = 50
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }

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

  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "ACL para subnet backend publica"
    Environment = var.environment
  }
}

#### Network ACL - Subnet Privada Frontend ####
resource "aws_network_acl" "nacl-private-frontend" {
  vpc_id     = aws_vpc.vpc-itm-rag-legal.id
  subnet_ids = [aws_subnet.subnet-private-frontend.id]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name        = "ACL para subnet frontend privada"
    Environment = var.environment
  }
}

#### Network ACL - Subnet Privada Backend ####
resource "aws_network_acl" "nacl-private-backend" {
  vpc_id     = aws_vpc.vpc-itm-rag-legal.id
  subnet_ids = [aws_subnet.subnet-private-backend.id]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.vpc-itm-rag-legal.cidr_block
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name        = "ACL para subnet backend privada"
    Environment = var.environment
  }
}

########## Security Groups ##########
resource "aws_security_group" "secgroup-public-frontend" {
  name        = "secgroup-frontend-web"
  description = "Permite trafico HTTP, HTTPS y SSH"
  vpc_id      = aws_vpc.vpc-itm-rag-legal.id

  ingress {
    description = "Acceso administrativo total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_ip]
  }

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "SG Frontend Publico"
    Environment = var.environment
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg-${var.environment}"
  description = "Security Group para EFS (NFS 2049)"
  vpc_id      = aws_vpc.vpc-itm-rag-legal.id

  ingress {
    description = "Acceso administrativo total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "NFS desde la VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block]
  }

  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "efs-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-${var.environment}"
  description = "Security Group para RDS PostgreSQL (5432)"
  vpc_id      = aws_vpc.vpc-itm-rag-legal.id

  ingress {
    description = "Acceso administrativo total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "PostgreSQL desde la VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block]
  }

  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "rds-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "secgroup-k3s-ssm-endpoints" {
  description = "Security Group para los VPC Endpoints de SSM del cluster K3S"
  vpc_id      = aws_vpc.vpc-itm-rag-legal.id

  ingress {
    description = "Acceso administrativo total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "HTTPS desde la VPC hacia VPC Endpoints SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block]
  }

  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "secgroup-k3s-ssm-endpoints-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_security_group" "secgroup-cluster-k3s" {
  description = "Security Group para los nodos del cluster K3S (red privada, sin SSH)"
  vpc_id      = aws_vpc.vpc-itm-rag-legal.id

  ingress {
    description = "Acceso administrativo total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_ip]
  }

  # API Server de Kubernetes (solo desde dentro de la VPC)
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block]
  }

  # Flannel VXLAN (overlay network entre nodos)
  ingress {
    description = "Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block]
  }

  # Métricas de Kubelet
  ingress {
    description = "Kubelet metrics"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block]
  }

  # NodePort services (solo desde dentro de la VPC)
  ingress {
    description = "NodePort Services (interno VPC)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block]
  }

  # Ingress HTTP para acceso por path (/n8n, /ollama) dentro de la VPC
  ingress {
    description = "Ingress HTTP desde VPC y admin_ip"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block, var.admin_ip]
  }

  # Ingress HTTPS para acceso por path (/n8n, /ollama) dentro de la VPC
  ingress {
    description = "Ingress HTTPS desde VPC y admin_ip"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc-itm-rag-legal.cidr_block, var.admin_ip]
  }

  # Todo el tráfico saliente permitido (necesario para NAT → internet y VPC Endpoints)
  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "secgroup-cluster-k3s-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.vpc-itm-rag-legal.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-private-backend.id]
  security_group_ids  = [aws_security_group.secgroup-k3s-ssm-endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "vpce-ssm-k3s-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.vpc-itm-rag-legal.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-private-backend.id]
  security_group_ids  = [aws_security_group.secgroup-k3s-ssm-endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "vpce-ssmmessages-k3s-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.vpc-itm-rag-legal.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet-private-backend.id]
  security_group_ids  = [aws_security_group.secgroup-k3s-ssm-endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "vpce-ec2messages-k3s-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group-${var.environment}"
  subnet_ids = [aws_subnet.subnet-private-frontend.id, aws_subnet.subnet-private-backend.id]

  tags = {
    Name        = "rds-subnet-group-${var.environment}"
    Environment = var.environment
  }
}
