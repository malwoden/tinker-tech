output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnet_ids" {
  value = {
    for k, subnet in aws_subnet.private : k => subnet.id
  }
  description = "value is a map of az to private subnet id"
}

output "public_subnet_ids" {
  value = {
    for k, subnet in aws_subnet.public : k => subnet.id
  }
  description = "value is a map of az to public subnet id"
}
