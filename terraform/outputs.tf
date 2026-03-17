output "aws_region" {
  value = var.aws_region
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_2.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "security_group_id" {
  value = aws_security_group.ec2_sg.id
}

output "ec2_instance_id" {
  value = aws_instance.app_server.id
}

output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "ec2_worker_instance_id" {
  value = aws_instance.worker_server.id
}

output "ec2_worker_public_ip" {
  value = aws_instance.worker_server.public_ip
}

output "lambda_function_name" {
  value = aws_lambda_function.ip_validator.function_name
}

output "api_gateway_url" {
  value = aws_apigatewayv2_api.lambda_api.api_endpoint
}

output "cloudwatch_dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "ec2_role_name" {
  value = aws_iam_role.ec2_role.name
}

output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}