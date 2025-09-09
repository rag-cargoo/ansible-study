variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "AKI"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_a" {
  description = "Availability Zone A"
  type        = string
  default     = "ap-northeast-2a"
}

variable "az_b" {
  description = "Availability Zone B"
  type        = string
  default     = "ap-northeast-2c"
}

variable "public_subnet_a_cidr" {
  description = "The CIDR block for public subnet A."
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "The CIDR block for public subnet B."
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
  description = "The CIDR block for private subnet A."
  type        = string
  default     = "10.0.101.0/24"
}

variable "private_subnet_b_cidr" {
  description = "The CIDR block for private subnet B."
  type        = string
  default     = "10.0.102.0/24"
}

variable "instance_type" {
  description = "The type of EC2 instance to launch."
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "The name of the EC2 key pair to use."
  type        = string
  default     = "test_key"
}

variable "my_ip" {
  description = "Your public IP address to allow SSH access."
  type        = string
  default     = "0.0.0.0/0" # WARNING: This allows SSH from anywhere. Change to your IP.
}

variable "private_app_a_ip" {
  description = "Fixed private IP for private_app_a instance."
  type        = string
  default     = "10.0.101.10"
}

variable "private_app_b_ip" {
  description = "Fixed private IP for private_app_b instance."
  type        = string
  default     = "10.0.102.10"
}

variable "private_monitoring_ip" {
  description = "Fixed private IP for private_monitoring instance."
  type        = string
  default     = "10.0.101.11"
}