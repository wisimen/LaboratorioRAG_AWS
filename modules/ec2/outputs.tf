output "instance_id" {
  description = "ID de la instancia EC2 frontend"
  value       = aws_instance.web_frontend.id
}

output "public_ip" {
  description = "IP publica de la instancia EC2 frontend"
  value       = aws_instance.web_frontend.public_ip
}

output "public_url" {
  description = "URL publica para acceder a la instancia"
  value       = "http://${aws_instance.web_frontend.public_ip}"
}
