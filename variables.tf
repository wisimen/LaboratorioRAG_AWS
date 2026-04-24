# Region
variable "aws_region" {
  default = "us-east-1"
}

# Profile
variable "aws_profile" {
  default = "default"
}

# Admin IP
variable "admin_ip" {
  default = "181.205.56.18/32"
}

variable "k3s_root_volume_size_gb" {
  description = "Tamaño del disco raíz (GB) para nodos K3S"
  type        = number
  default     = 80
}

variable "environment_name" {
  description = "Nombre del entorno"
  type        = map(string)
  default = {
    "default" = "default",
    "prod"    = "prod",
    "test"    = "test",
    "dev"     = "dev"
  }
}

# Availability Zones
variable "aws_availability_zone_1" {
  default = "us-east-1a"
}

# Availability Zones
variable "aws_availability_zone_2" {
  default = "us-east-1b"
}

# VPC CIDR Block
variable "vpc_cidr" {
  type = map(string)
  default = {
    "default" = "216.216.0.0/22",
    "prod"    = "216.216.0.0/22",
    "test"    = "217.217.0.0/22",
    "dev"     = "218.218.0.0/22"
  }
}

# Subnet frontend - publico 
variable "subnet_public_frontend_cidr_block" {
  description = "La Ip de la subred para el frontend"
  type        = map(string)
  default = {
    "default" = "216.216.0.0/24",
    "prod"    = "216.216.0.0/24",
    "test"    = "217.217.0.0/24",
    "dev"     = "218.218.0.0/24"
  }
}
# Subnet frontend - privado 
variable "subnet_private_frontend_cidr_block" {
  description = "La Ip de la subred para el frontend"
  type        = map(string)
  default = {
    "default" = "216.216.1.0/24",
    "prod"    = "216.216.1.0/24",
    "test"    = "217.217.1.0/24",
    "dev"     = "218.218.1.0/24"
  }
}

# Subnet backend - publico
variable "subnet_public_backend_cidr_block" {
  description = "La Ip de la subred para el backend"
  type        = map(string)
  default = {
    "default" = "216.216.2.0/24",
    "prod"    = "216.216.2.0/24",
    "test"    = "217.217.2.0/24",
    "dev"     = "218.218.2.0/24"
  }
}
# Subnet backend - privado
variable "subnet_private_backend_cidr_block" {
  description = "La Ip de la subred para el backend"
  type        = map(string)
  default = {
    "default" = "216.216.3.0/24",
    "prod"    = "216.216.3.0/24",
    "test"    = "217.217.3.0/24",
    "dev"     = "218.218.3.0/24"
  }
}


###### ACL Network ######
variable "acl_network_name" {
  description = "The name for the Network ACL"
  type        = map(string)
  default = {
    "default" = "ACL-ITMPruebas",
    "prod"    = "ACL-ITMProd",
    "test"    = "ACL-ITMTest",
    "dev"     = "ACL-ITMDev"
  }
}

###### Route Table ######
variable "route_table_cidr_block" {
  description = "The CIDR block for the route table"
  type        = map(string)
  default = {
    "default" = "0.0.0.0/0",
    "prod"    = "0.0.0.0/0",
    "test"    = "0.0.0.0/0",
    "dev"     = "0.0.0.0/0"
  }
}

###### RDS PostgreSQL ######

variable "rds_engine" {
  description = "Motor de base de datos RDS"
  type        = map(string)
  default = {
    "default" = "postgres"
    "prod"    = "postgres"
    "test"    = "postgres"
    "dev"     = "postgres"
  }
}

variable "rds_engine_version" {
  description = "Version del motor RDS"
  type        = map(string)
  default = {
    "default" = "17.6"
    "prod"    = "17.6"
    "test"    = "17.6"
    "dev"     = "17.6"
  }
}

variable "rds_instance_class" {
  description = "Clase de instancia RDS"
  type        = map(string)
  default = {
    "default" = "db.t4g.micro"
    "prod"    = "db.t4g.small"
    "test"    = "db.t4g.micro"
    "dev"     = "db.t4g.micro"
  }
}

variable "rds_allocated_storage" {
  description = "Almacenamiento asignado a RDS en GB"
  type        = map(number)
  default = {
    "default" = 20
    "prod"    = 100
    "test"    = 20
    "dev"     = 20
  }
}

variable "rds_db_name" {
  description = "Nombre de la base de datos RDS"
  type        = map(string)
  default = {
    "default" = "n8ndb"
    "prod"    = "n8ndb"
    "test"    = "n8ndb"
    "dev"     = "n8ndb"
  }
}

variable "rds_username" {
  description = "Usuario administrativo de RDS"
  type        = map(string)
  default = {
    "default" = "n8nadmin"
    "prod"    = "n8nadmin"
    "test"    = "n8nadmin"
    "dev"     = "n8nadmin"
  }
}

variable "rds_password" {
  description = "Password administrativo de RDS"
  type        = map(string)
  sensitive   = true
  default = {
    "default" = "TestOnlyDefaultPass123!"
    "prod"    = "TestOnlyProdPass123!"
    "test"    = "TestOnlyTestPass123!"
    "dev"     = "TestOnlyDevPass123!"
  }
}

variable "rds_skip_final_snapshot" {
  description = "Controla si RDS omite snapshot final al destruir"
  type        = map(bool)
  default = {
    "default" = true
    "prod"    = false
    "test"    = true
    "dev"     = true
  }
}

variable "n8n_encryption_key" {
  description = "Clave de encriptación para n8n"
  type        = map(string)
  sensitive   = true
  default = {
    "default" = "testEncryptionKey123DefaultWorkspace!"
    "prod"    = "testEncryptionKeyProd123!"
    "test"    = "testEncryptionKeyTest123!"
    "dev"     = "testEncryptionKeyDev123!"
  }
}

variable "n8n_port" {
  description = "Puerto NodePort para n8n (rango 30000-32767)"
  type        = map(number)
  default = {
    "default" = 30567
    "prod"    = 30567
    "test"    = 30567
    "dev"     = 30567
  }
}
