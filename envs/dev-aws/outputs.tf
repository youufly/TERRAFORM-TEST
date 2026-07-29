output "url_publique" {
  description = "URL HTTP de l'instance web deployee."
  value       = "http://${aws_instance.web.public_ip}"
}
