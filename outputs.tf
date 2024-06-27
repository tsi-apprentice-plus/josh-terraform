output "instanceip" {
  value = aws_eip.instance_eip.address
}