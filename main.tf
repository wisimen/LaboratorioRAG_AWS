########## VPC ##########
# / -> VPC

resource "aws_vpc" "vpc-itm-rag-legal" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc-itm-rag-legal"

  }
}

########## Subnets ##########
# / -> VPC -> Subnet
# Subnet frontend publica
resource "aws_subnet" "subnet-public-frontend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_public_frontend_cidr_block
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "Sub red de fontend publica"
  }
}

########## Subnet 2 ##########
resource "aws_subnet" "subnet-private-frontend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_private_frontend_cidr_block
  availability_zone       = var.aws_availability_zone_2
  map_public_ip_on_launch = false

  tags = {
    Name = "Sub red de fontend privada"
  }
}

########## Subnet 3 ##########
resource "aws_subnet" "subnet-public-backend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_public_backend_cidr_block
  availability_zone       = var.aws_availability_zone_1
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Sub red de backend publica"
  }
}

########## Subnet 4 ##########
resource "aws_subnet" "subnet-private-backend" {
  vpc_id                  = aws_vpc.vpc-itm-rag-legal.id
  cidr_block              = var.subnet_private_backend_cidr_block
  availability_zone       = var.aws_availability_zone_2
  map_public_ip_on_launch = false

  tags = {
    Name = "Sub red de backend privada"
  }
}


############ Internet Gateway ##########
# / -> VPC -> Internet Gateway
resource "aws_internet_gateway" "igw-itm-rag-legal" {
  vpc_id = aws_vpc.vpc-itm-rag-legal.id
  tags = {
    Name = "Internet Gateway de itm rag legal"
  }
}

############ Route Table ##########
# / -> VPC -> Route Table
resource "aws_route_table" "rtb-itm-rag-legal" {
  vpc_id = aws_vpc.vpc-itm-rag-legal.id
  cidr_block = var.route_table_cidr_block
  tags = {
    Name = "Route Table de itm rag legal"
  }
    depends_on = [ aws_internet_gateway.igw-itm-rag-legal ]
} 

# #### Creamos el ACL ####

# resource "aws_network_acl" "ACLITMPruebas" {
#     vpc_id = aws_vpc.VPCITMPruebas.id
#     subnet_ids = [
#         aws_subnet.subnet_backend_1.id,
#         aws_subnet.subnet_backend_2.id,
#         aws_subnet.subnet_frontend_1.id,
#         aws_subnet.subnet_frontend_2.id,
#         aws_subnet.subnet_database_1.id
#     ]
#             ingress = [
#         {
#             protocol   = "tcp"
#             rule_no    = 100
#             action     = "deny"
#             cidr_block = "0.0.0.0/0"
#             from_port  = 1433
#             to_port    = 1433
#             icmp_type  = null
#             icmp_code  = null
#             ipv6_cidr_block = null
#         },
#         {
#             protocol   = "tcp"
#             rule_no    = 200
#             action     = "allow"
#             cidr_block = var.vpc_ip_cidr
#             from_port  = 1433
#             to_port    = 1433
#             icmp_type  = null
#             icmp_code  = null
#             ipv6_cidr_block = null
#         },
#         {
#             protocol   = "tcp"
#             rule_no    = 250
#             action     = "allow"
#             cidr_block = "0.0.0.0/0"
#             from_port  = 22
#             to_port    = 22
#             icmp_type  = null
#             icmp_code  = null
#             ipv6_cidr_block = null
#         },
#         {
#             protocol   = "tcp"
#             rule_no    = 300
#             action     = "allow"
#             cidr_block = "0.0.0.0/0"
#             from_port  = 443
#             to_port    = 443
#             icmp_type  = null
#             icmp_code  = null
#             ipv6_cidr_block = null
#         },
#         {
#             protocol   = "tcp"
#             rule_no    = 400
#             action     = "allow"
#             cidr_block = "0.0.0.0/0"
#             from_port  = 80
#             to_port    = 80
#             icmp_type  = null
#             icmp_code  = null
#             ipv6_cidr_block = null
#         }
#     ]
# 
#     egress = [
#         {
#             protocol   = "tcp"
#             rule_no    = 100
#             action     = "allow"
#             cidr_block = "0.0.0.0/0"
#             from_port  = 0
#             to_port    = 0
#             icmp_type  = null
#             icmp_code  = null
#             ipv6_cidr_block = null
#         },
#         {
#             protocol   = "tcp"
#             rule_no    = 110 # Egress for HTTP
#             action     = "allow"
#             cidr_block = "0.0.0.0/0"
#             from_port  = 80
#             to_port    = 80
#             icmp_type  = null
#             icmp_code  = null
#             ipv6_cidr_block = null
#         },
#         {
#             protocol   = "tcp"
#             rule_no    = 120 # Egress for HTTPS
#             action     = "allow"
#             cidr_block = "0.0.0.0/0"
#             from_port  = 443
#             to_port    = 443
#             icmp_type  = null
#             icmp_code  = null
#             ipv6_cidr_block = null
#         }
#     ]
# 
#     tags = {
#         Name = var.acl_network_name
#         Environment = var.environment_name
#     }
# }