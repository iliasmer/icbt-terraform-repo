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

output "private_subnet_cidr_blocks" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private_subnet.*.cidr_block
}


output "route_tables_private_subnet" {
  description = "List of private subnet route table IDs"
  value       = aws_route_table.route_table_private.*.id
}