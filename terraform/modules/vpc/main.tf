locals {
  resource_name_prefix = "${var.environment}-${var.region}" 
}

# VPC: VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = merge(var.tags,
    {
      Name = "${local.resource_name_prefix}-vpc"
  })
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  # Add these empty lists to make sure there are no rules in the SG
  # Reference: https://github.com/hashicorp/terraform-provider-aws/issues/20697#issuecomment-1266908264
  ingress = []
  egress  = []

  tags = merge(var.tags,
    {
      Name = "${local.resource_name_prefix}-vpc-default-sg"
  })
}

# VPC: private subnets
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.private_subnet_azs[count.index]

  tags = merge(var.tags,
    {
      Name = "${local.resource_name_prefix}-${var.private_subnet_name[count.index]}"
  })
}


# VPC: Route tables private subnet
resource "aws_route_table" "route_table_private" {
  count = length(var.private_subnet_cidr)

  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags,
    {
      Name = "${local.resource_name_prefix}-${element(var.private_subnet_name, count.index)}"
  })
}

# VPC: Route tables association private subnet 
resource "aws_route_table_association" "route_table_association_private" {
  count = length(var.private_subnet_cidr)

  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.route_table_private[*].id, count.index)
}

# VPC Endpoints

# S3 endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = aws_route_table.route_table_private[*].id
  tags = {
    Name = "${local.resource_name_prefix}-vpc-s3-endpoint"
  }
}

#Interface endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${local.resource_name_prefix}-vpc-endpoint-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Security group for VPC endpoints"
  tags = {
    Name = "${local.resource_name_prefix}-vpc-endpoint-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_sg" {
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  description       = "Allow all egress from endpoint ENIs"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_sg" {
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  description       = "Allow all traffic in via VPC endpoints from within the VPC"
  cidr_ipv4         = var.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_endpoint" "sqs_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = slice(aws_subnet.private_subnet[*].id, 0, var.endpoint_nr_azs)
  tags = {
    Name = "${local.resource_name_prefix}-vpc-sqs-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = slice(aws_subnet.private_subnet[*].id, 0, var.endpoint_nr_azs)
  tags = {
    Name = "${local.resource_name_prefix}-vpc-ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "dkr_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = slice(aws_subnet.private_subnet[*].id, 0, var.endpoint_nr_azs)
  tags = {
    Name = "${local.resource_name_prefix}-vpc-ecr-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = slice(aws_subnet.private_subnet[*].id, 0, var.endpoint_nr_azs)

  tags = {
    Name = "${local.resource_name_prefix}-vpc-ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = slice(aws_subnet.private_subnet[*].id, 0, var.endpoint_nr_azs)

  tags = {
    Name = "${local.resource_name_prefix}-vpc-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = slice(aws_subnet.private_subnet[*].id, 0, var.endpoint_nr_azs)

  tags = {
    Name = "${local.resource_name_prefix}-vpc-ec2messages-endpoint"
  }
}

resource "aws_vpc_endpoint" "logs_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = slice(aws_subnet.private_subnet[*].id, 0, var.endpoint_nr_azs)

  tags = {
    Name = "${local.resource_name_prefix}-vpc-logs-endpoint"
  }
}
