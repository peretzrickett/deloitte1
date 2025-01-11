# -----------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------
# Data Resources - IAM Trust and Policies
# -----------------------------------------------------------
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Example of least-privilege policy: EC2 can only read a specific S3 bucket
data "aws_iam_policy_document" "ec2_least_priv" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::my-example-bucket/*", # Replace with your actual bucket if needed
      "arn:aws:s3:::my-example-bucket"
    ]
  }
}

# CloudWatch Logs policy for VPC Flow Logs
data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_logs_role_policy" {
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
}

# -----------------------------------------------------------
# VPC, Subnet, and Internet Gateway
# -----------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "my-secure-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block             = var.subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-internet-gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# -----------------------------------------------------------
# VPC Flow Logs (PR.PT-1)
# -----------------------------------------------------------
resource "aws_iam_role" "flow_logs_role" {
  name               = "flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json
}

resource "aws_iam_role_policy" "flow_logs_role_policy" {
  name   = "flow-logs-role-policy"
  role   = aws_iam_role.flow_logs_role.id
  policy = data.aws_iam_policy_document.flow_logs_role_policy.json
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name              = "/aws/vpc/flow-logs/my-secure-vpc"
  retention_in_days = 7
}

# Updated VPC Flow Logs resource
resource "aws_flow_log" "vpc_flow_logs" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
}

# -----------------------------------------------------------
# S3 Bucket with Encryption (PR.DS-1)
# -----------------------------------------------------------
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "my-secure-encrypted-bucket-${random_id.s3_suffix.hex}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "my-secure-encrypted-bucket"
  }
}

resource "random_id" "s3_suffix" {
  byte_length = 4
}

# Optional: Bucket policy to enforce encryption and SSL
data "aws_iam_policy_document" "s3_encryption_policy" {
  statement {
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.secure_bucket.arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
  statement {
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.secure_bucket.arn,
      "${aws_s3_bucket.secure_bucket.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "secure_bucket_policy" {
  bucket = aws_s3_bucket.secure_bucket.bucket
  policy = data.aws_iam_policy_document.s3_encryption_policy.json
}

# -----------------------------------------------------------
# EC2 with IAM Role + Restricted Ingress (PR.AC-3)
# -----------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy" "ec2_policy" {
  name   = "ec2_least_priv_policy"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.ec2_least_priv.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Security Group for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.trusted_ip_range]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "my-secure-ec2"
  }
}
