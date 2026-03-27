########## S3 Bucket - Almacenamiento de objetos para Pods ##########
# Utilizado por los pods del cluster K3S para almacenar objetos (backups, artefactos, etc.)

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "k3s-storage" {
  # El ID de cuenta garantiza un nombre de bucket globalmente único
  bucket = "k3s-storage-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "k3s-storage-${var.environment}"
    Environment = var.environment
  }
}

# Habilitar versionado para proteger los objetos almacenados
resource "aws_s3_bucket_versioning" "k3s-storage-versioning" {
  bucket = aws_s3_bucket.k3s-storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado en reposo del bucket S3
resource "aws_s3_bucket_server_side_encryption_configuration" "k3s-storage-encryption" {
  bucket = aws_s3_bucket.k3s-storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear todo acceso público al bucket
resource "aws_s3_bucket_public_access_block" "k3s-storage-public-access" {
  bucket = aws_s3_bucket.k3s-storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


########## Security Group - EFS ##########
# Permite tráfico NFS (puerto 2049) solo desde los nodos del cluster K3S

resource "aws_security_group" "secgroup-k3s-efs" {
  description = "Security Group para el EFS del cluster K3S"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS desde nodos K3S"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.secgroup-cluster-k3s.id]
  }

  egress {
    description = "Permitir toda la salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-efs-k3s-${var.environment}"
    Environment = var.environment
  }
}


########## EFS - Almacenamiento persistente para Pods ##########
# Montado en los nodos K3S como Persistent Volume (RWX) para los pods

resource "aws_efs_file_system" "k3s-efs" {
  creation_token   = "k3s-efs-${var.environment}"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  tags = {
    Name        = "k3s-efs-${var.environment}"
    Environment = var.environment
  }
}

# Mount target: punto de montaje NFS en la subnet de los nodos K3S
resource "aws_efs_mount_target" "k3s-efs-mount" {
  file_system_id  = aws_efs_file_system.k3s-efs.id
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.secgroup-k3s-efs.id]
}
