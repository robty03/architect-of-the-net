variable "aws_region" {
  description = "AWS region for the project"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "ip-spectre"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  description = "Availability zone for subnet 1"
  type        = string
  default     = "eu-west-1a"
}

variable "availability_zone_2" {
  description = "Availability zone for subnet 2"
  type        = string
  default     = "eu-west-1b"
}

variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name for EC2 SSH access"
  type = string
  default = "ip-spectre-key"
}