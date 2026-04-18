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
