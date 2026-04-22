########## EFS Regional - Storage Persistente Multi-AZ ##########

resource "aws_efs_file_system" "k3s_storage_efs" {
  creation_token   = "k3s-storage-efs-${var.environment}"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "k3s-storage-efs-${var.environment}"
    Environment = var.environment
    Tier        = "multi-az"
  }
}

resource "aws_efs_mount_target" "k3s_storage_efs_mount_targets" {
  for_each       = toset(var.subnet_ids)
  file_system_id  = aws_efs_file_system.k3s_storage_efs.id
  subnet_id       = each.value
  security_groups = [var.efs_sg_id]
}

resource "aws_efs_backup_policy" "k3s_storage_efs_backup" {
  file_system_id = aws_efs_file_system.k3s_storage_efs.id

  backup_policy {
    status = "DISABLED"
  }
}