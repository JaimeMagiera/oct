output "instance_ip_addr" {
  value = aws_instance.fcos_instance.public_ip
}
