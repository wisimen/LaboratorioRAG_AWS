resource "aws_instance" "web_frontend" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip_address

  user_data = <<-EOF_USER_DATA
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hola Mundo desde mi Frontend en AWS! 🚀</h1>" > /var/www/html/index.html
              EOF_USER_DATA

  tags = {
    Name        = "EC2 Frontend Web"
    Environment = var.environment
  }
}
