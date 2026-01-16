output "vpc_id" {
  description = "VPC Id"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.vpc.cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_subnet.*.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_subnet.*.id
}

output "private_subnet_cidr_blocks" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private_subnet.*.cidr_block
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public_subnet.*.cidr_block
}

output "route_tables_private_subnet" {
  description = "List of private subnet route table IDs"
  value       = aws_route_table.route_table_private.*.id
}

output "route_tables_public_subnet" {
  description = "List of public subnet route table IDs"
  value       = aws_route_table.route_table_public.*.id
}

output "private_hosted_zone_id" {
  description = "Route 53 private zone id"
  value       = var.private_hosted_zone_name != null ? aws_route53_zone.private_hosted_zone["this"].zone_id : null
}

output "private_hosted_zone_name" {
  description = "Route 53 private zone name"
  value       = var.private_hosted_zone_name
}
