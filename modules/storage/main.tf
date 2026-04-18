########## EFS One Zone - Storage Persistente de Bajo Costo ##########

resource "aws_efs_file_system" "k3s_storage_efs" {
  creation_token   = "k3s-storage-efs-onezone-${var.environment}"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  availability_zone_name = var.availability_az

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "k3s-storage-efs-onezone-${var.environment}"
    Environment = var.environment
    Tier        = "low-cost"
  }
}

resource "aws_efs_mount_target" "k3s_storage_efs_onezone_mount" {
  file_system_id  = aws_efs_file_system.k3s_storage_efs.id
  subnet_id       = var.subnet_id
  security_groups = [var.efs_sg_id]
}

resource "aws_efs_backup_policy" "k3s_storage_efs_onezone_backup" {
  file_system_id = aws_efs_file_system.k3s_storage_efs.id

  backup_policy {
    status = "DISABLED"
  }
}