########## RDS Instance - PostgreSQL para n8n ##########

resource "aws_db_instance" "n8n_postgres" {
  # Identificador y nombre
  identifier     = "n8n-db-${var.environment}"
  db_name        = var.db_name
  engine         = var.engine
  engine_version = var.engine_version

  # Instancia y almacenamiento
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  # Credenciales
  username = var.username
  password = var.password

  # Networking
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.vpc_security_group_ids]
  publicly_accessible    = false

  # Backup y mantenimiento
  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "n8n-db-final-snapshot-${var.environment}"

  # Performance y Multi-AZ
  multi_az = false

  # Encriptación
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_key.arn

  # Parámetros adicionales
  auto_minor_version_upgrade      = true
  deletion_protection             = var.environment == "prod" ? true : false
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name        = "n8n-postgresdb-${var.environment}"
    Environment = var.environment
    Application = "n8n"
  }

  depends_on = [aws_security_group_rule.allow_postgres]
}

########## KMS Key para encriptación de RDS ##########

resource "aws_kms_key" "rds_key" {
  description             = "KMS key para encriptación de RDS n8n-${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "rds-key-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/rds-n8n-${var.environment}"
  target_key_id = aws_kms_key.rds_key.key_id
}

########## Security Group Rule para permitir acceso desde K3S ##########

resource "aws_security_group_rule" "allow_postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.vpc_security_group_ids
  source_security_group_id = var.source_security_group_id

  lifecycle {
    create_before_destroy = true
  }
}
