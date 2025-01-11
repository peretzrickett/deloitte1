variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources in"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "trusted_ip_range" {
  type        = string
  description = "IP range allowed to SSH into EC2"
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance"
  # Example for Amazon Linux 2 in us-east-1:
  default     = "ami-08c40ec9ead489470"
}
