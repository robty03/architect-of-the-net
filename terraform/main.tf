locals {
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_1_cidr
  availability_zone = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public_subnet_1"
  })
}

resource "aws_subnet" "public_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_2_cidr
  availability_zone = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public_subnet_2"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public_1" {
  subnet_id = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2_sg" {
  name = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH access"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-sg"
  })
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["137112412989"]

  filter {
    name = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app_server" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-server"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "worker_server" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-worker-server"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-lambda-role"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "ip_validator" {
  function_name = "${var.project_name}-ip-validator"
  role = aws_iam_role.lambda_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.11"
  filename = "${path.module}/../lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda_function.zip")

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ip-validator"
  })
}

resource "aws_apigatewayv2_api" "lambda_api" {
  name = "${var.project_name}-http-api"
  protocol_type = "HTTP"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-http-api"
  })
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.ip_validator.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "validate_route" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /validate"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  name = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ip_validator.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0
        y = 0
        width = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app_server.id],
            [".", ".", "InstanceId", aws_instance.worker_server.id]
          ]
          period = 300
          stat = "Average"
          region = var.aws_region
          title = "EC2 CPU Utilization"
        }
      },
      {
        type = "metric"
        x = 12
        y = 0
        width = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.ip_validator.function_name],
            [".", "Errors", ".", "."]
          ]
          period = 300
          stat = "Sum"
          region = var.aws_region
          title = "Lambda Invocations and Errors"
        }
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-role"
  })
}

resource "aws_iam_policy" "ec2_app_policy" {
  name = "${var.project_name}-ec2-app-policy"
  description = "Policy for EC2 to access DynamoDB and SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:DeleteItem"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_app_policy_attach" {
  role = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}