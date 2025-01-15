# Deloitte Cloud Security Architecture

A demonstration of deploying a **secure AWS environment** with **Terraform**. This setup maps to three NIST CSF Protect (PR) subcategories:

1. **PR.PT (Protective Technology)**  
2. **PR.DS (Data Security)**  
3. **PR.AC (Identity Management and Access Control)**  

---

## Table of Contents

- [Deloitte Cloud Security Architecture](#deloitte-cloud-security-architecture)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Architecture](#architecture)
  - [Prerequisites](#prerequisites)
  - [Project Structure](#project-structure)
  - [Installation and Setup](#installation-and-setup)

---

## Overview

This project creates several AWS resources that fulfill core security requirements:

- **VPC + Flow Logs (PR.PT-1)**: Log inbound/outbound traffic to CloudWatch.  
- **S3 Bucket with Encryption (PR.DS-1)**: Default encryption at rest (AES-256).  
- **EC2 with IAM Role + Restricted Security Group (PR.AC-3)**: No hardcoded credentials, inbound SSH locked down.

All infrastructure is declared in **Terraform** for consistent, repeatable deployments.

---

## Architecture

1. **VPC, Subnet, and Internet Gateway**  
   - A single VPC with a **public subnet** hosting the EC2 instance.  
2. **Flow Logs**  
   - Captures VPC network traffic and sends logs to **CloudWatch Logs**.  
3. **S3 Bucket**  
   - Enforces **server-side encryption** (AES-256 or KMS).  
   - (Optional) Bucket policy for secure transport (HTTPS only) and encryption.  
4. **EC2 Instance**  
   - **IAM Instance Profile** for least privilege (no static credentials on disk).  
   - **Security Group** restricting inbound SSH to a specific CIDR block or 0.0.0.0/0 for demo.

---

## Prerequisites

- **AWS Account** with permissions to create:
  - VPC, Subnets, Security Groups, EC2, S3, IAM, CloudWatch Logs
- **Terraform** 1.x or newer
- **AWS CLI** (optional but recommended for verification)

---

## Project Structure

deloitte1/
├── main.tf                # Main Terraform configuration
├── variables.tf           # Variable definitions for AWS region, CIDRs, etc.
├── outputs.tf             # Optional outputs for easy reference
├── terraform.tfvars       # Local variable overrides (if used)
├── README.md              # This file
└── ...                    # .git, other files, etc.

---

## Installation and Setup

1. **Clone the Repo**

```bash
git clone https://github.com/peretzrickett/deloitte1.git
cd deloitte1
```

AWS Credentials
Configure your AWS credentials locally (if you haven’t yet):
bash
Copy code
aws configure
Provide your AWS Access Key, Secret Access Key, default region, and output format.
Alternatively, set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as environment variables.
Deployment
Initialize Terraform
bash
Copy code
terraform init
Installs necessary providers (AWS) and sets up your local Terraform environment.
Plan and Apply
Review the Plan:

bash
Copy code
terraform plan
This shows which resources Terraform will create or modify.
Deploy Infrastructure:

bash
Copy code
terraform apply
Type yes when prompted.
Wait for Terraform to create the VPC, S3 bucket, EC2 instance, etc.
Verification
VPC:

Check the AWS VPC Console → Your VPCs.
Confirm Flow Logs are enabled, and logs appear in CloudWatch.
S3:

Go to the AWS S3 Console → Buckets, find the deployed bucket.
Confirm Default Encryption is set to AES-256 or KMS.
EC2:

Check the AWS EC2 Console → Instances.
Validate the instance has the IAM Instance Profile attached (no credentials in .ssh config).
Security Group should restrict inbound SSH either to 0.0.0.0/0 (demo) or your IP range.
Outputs
Run:

bash
Copy code
terraform output
You’ll see:

vpc_id: ID of the created VPC
s3_bucket_name: Name of the secure S3 bucket
ec2_public_ip: Public IP address of the EC2 instance
Teardown
When finished, destroy all resources:

bash
Copy code
terraform destroy
Type yes to confirm.
The VPC, S3 bucket (if empty), IAM roles, and EC2 instance will be removed to avoid costs.
NIST CSF Mapping
Category	AWS Resource	Terraform Reference
PR.PT-1	VPC Flow Logs to CloudWatch (monitor inbound/outbound traffic)	aws_flow_log.vpc_flow_logs
PR.DS-1	S3 Bucket Encryption (server-side encryption at rest)	aws_s3_bucket.secure_bucket
PR.AC-3	EC2 Instance + IAM Role (no embedded credentials) + Security Group	aws_instance.ec2_instance and aws_security_group.ec2_sg
Notes and Warnings
SSH Inbound
Using 0.0.0.0/0 for SSH access is not recommended for production, but okay for a quick demo.
S3 Bucket Deletion
If the S3 bucket still has objects, terraform destroy may fail. Empty the bucket first.
Deprecation Warnings
If you see references to deprecated arguments (e.g., log_group_name for Flow Logs or S3 encryption in the aws_s3_bucket resource), you can update to recommended arguments (log_destination or aws_s3_bucket_server_side_encryption_configuration).