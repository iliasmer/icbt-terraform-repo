data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  resource_name_prefix = var.custom_vpc_resource_prefix == null ? "${var.customer}-${var.environment}-${var.region}" : var.custom_vpc_resource_prefix
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

# VPC: public subnets
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.public_subnet_azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags,
    {
      Name = "${local.resource_name_prefix}-${var.public_subnet_name[count.index]}"
  })
}

# VPC: Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  tags = merge(var.tags,
    {
      Name = "${local.resource_name_prefix}-igw"
  })
}

resource "aws_internet_gateway_attachment" "internet_gateway_attachment" {
  internet_gateway_id = aws_internet_gateway.internet_gateway.id
  vpc_id              = aws_vpc.vpc.id
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

# VPC: Route tables public subnet
resource "aws_route_table" "route_table_public" {
  count = length(var.public_subnet_cidr)

  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags,
    {
      Name = "${local.resource_name_prefix}-${element(var.public_subnet_name, count.index)}"
  })
}

# VPC: Route tables association public subnet 
resource "aws_route_table_association" "route_table_association_public" {
  count = length(var.public_subnet_cidr)

  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.route_table_public[*].id, count.index)
}

# VPC: Routes public subnet
resource "aws_route" "route_public_subnet" {
  count = length(var.public_subnet_cidr)

  route_table_id         = element(aws_route_table.route_table_public[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# VPC Endpoints

# S3 endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = concat(aws_route_table.route_table_private[*].id, aws_route_table.route_table_public[*].id)
  tags = {
    Name = "${local.resource_name_prefix}-vpc-s3-endpoint"
  }
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "arn:aws:s3:::*"
      }
    ]
  })
}

# VPC: Dynamodb endpoint
data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpc"

      values = [aws_vpc.vpc.id]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_vpc_endpoint" "dynamodb_endpoint" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids = concat(aws_route_table.route_table_private[*].id, aws_route_table.route_table_public[*].id)
  tags = {
    Name = "${local.resource_name_prefix}-vpc-dynamodb-endpoint"
  }
  policy = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
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
  description       = "Allow all traffic out via VPC endpoints"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_sg" {
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  description       = "Allow all traffic in via VPC endpoints from within the VPC"
  cidr_ipv4         = var.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


#Optional SQS endpoint
resource "aws_vpc_endpoint" "sqs_endpoint" {
  count = var.enable_sqs_endpoint == true ? 1 : 0

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

#Optional ECR endpoints
resource "aws_vpc_endpoint" "ecr_endpoint" {
  count = var.enable_ecr_endpoints == true ? 1 : 0

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
  count = var.enable_ecr_endpoints == true ? 1 : 0

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

#Optional SNS endpoint
resource "aws_vpc_endpoint" "sns_endpoint" {
  count = var.enable_sns_endpoint == true ? 1 : 0

  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = slice(aws_subnet.private_subnet[*].id, 0, var.endpoint_nr_azs)
  tags = {
    Name = "${local.resource_name_prefix}-vpc-sns-endpoint"
  }
}

moved {
  from = aws_route53_zone.private_hosted_zone
  to   = aws_route53_zone.private_hosted_zone["this"]
}
# VPC: Private zone
resource "aws_route53_zone" "private_hosted_zone" {
  for_each = var.private_hosted_zone_name != null ? toset(["this"]) : toset([])
  name     = var.private_hosted_zone_name
  comment  = "Private hosted zone for ${var.region}"

  vpc {
    vpc_id     = aws_vpc.vpc.id
    vpc_region = var.region
  }

  dynamic "vpc" {
    for_each = var.associated_vpc_id

    content {
      vpc_id     = vpc.value
      vpc_region = var.region
    }
  }

  tags = var.tags
}

# VPC: SSM Parameter VPC id
resource "aws_ssm_parameter" "ssm_parameter_vpc" {
  name        = "/${var.customer}/${var.environment}/VPC/VPCId${var.ssm_parameter_suffix_extension}"
  description = "VPC Id"
  type        = "String"
  value       = aws_vpc.vpc.id

  tags = var.tags
}

# VPC: SSM Parameter subnet1 id
resource "aws_ssm_parameter" "ssm_parameter_subnet" {
  count       = length(aws_subnet.private_subnet) > 0 ? 1 : 0
  name        = "/${var.customer}/${var.environment}/VPC/PrSubnet1Id"
  description = "PrSubnet1 Id"
  type        = "String"
  value       = aws_subnet.private_subnet[0].id

  lifecycle {
    ignore_changes = [value, version]
  }

  tags = var.tags
}

# VPC: flow log
resource "aws_flow_log" "vpc_flow_log" {
  count = var.enable_vpc_flow_log == true ? 1 : 0

  vpc_id               = aws_vpc.vpc.id
  iam_role_arn         = aws_iam_role.vpc_flow_log_role[0].arn
  log_destination      = aws_cloudwatch_log_group.vpc_log_group[0].arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = var.vpc_flow_log_traffic_type

  tags = var.tags
}

# VPC: flow log group
resource "aws_cloudwatch_log_group" "vpc_log_group" {
  count = var.enable_vpc_flow_log == true ? 1 : 0

  name              = "${local.resource_name_prefix}-vpcflowlogs-default-${var.log_group_name_suffix}"
  retention_in_days = var.vpc_flow_log_retention_in_days

  tags = var.tags
}

# VPC: flow log role
resource "aws_iam_role" "vpc_flow_log_role" {
  count = var.enable_vpc_flow_log == true ? 1 : 0

  name = "${local.resource_name_prefix}-${var.flow_log_role_name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# VPC: flow log role policy
resource "aws_iam_role_policy" "vpc_flow_log_role_policy" {
  count = var.enable_vpc_flow_log == true ? 1 : 0

  name = "flowlogs-policy"
  role = aws_iam_role.vpc_flow_log_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.vpc_log_group[0].name}:*"
      }
    ]
  })
}
