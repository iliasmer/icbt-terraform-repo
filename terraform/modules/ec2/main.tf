data "aws_caller_identity" "current" {}

resource "aws_instance" "ml_inference_host" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ml_inference_host_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ml_inference_host_profile.name

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }


  tags = {
    Name = "${var.name}"
  }

  user_data = templatefile(
    "${path.module}/../../user-data-${var.name}.sh",
    {
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
    }
  )

}

resource "aws_iam_role" "ml_inference_host_role" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ml_inference_host_ecr_policy" {
  role = aws_iam_role.ml_inference_host_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ml_inference_host_ssm" {
  role       = aws_iam_role.ml_inference_host_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ml_inference_host_profile" {
  name = "${var.name}-profile"
  role = aws_iam_role.ml_inference_host_role.name
}

resource "aws_security_group" "ml_inference_host_sg" {
  name        = "${var.name}-sg"
  description = "Allow HTTP access to ML inference services"

  ingress {
    description = "BentoML ${var.service_name} service"
    from_port   = var.service_port
    to_port     = var.service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
