This repository showcases a secure AWS environment built with Terraform. It addresses Part 1 of the Cloud Security Architect Challenge by focusing on three NIST CSF Protect (PR) categories/subcategories:

PR.PT (Protective Technology)
PR.DS (Data Security)
PR.AC (Identity Management and Access Control)
Table of Contents
Overview
Architecture
Prerequisites
Installation and Setup
Clone the Repo
Configure AWS Credentials
Deployment
Initialize Terraform
Plan and Apply
Verification
Outputs
Teardown
NIST CSF Mapping
Notes and Warnings
Contact
Overview
This project creates a three-control AWS setup demonstrating how to:

Capture VPC Flow Logs for audit and monitoring (PR.PT-1).
Encrypt data at rest in S3 using server-side encryption (PR.DS-1).
Secure an EC2 instance with an IAM role (no hardcoded credentials) and limited Security Group ingress (PR.AC-3).
All resources are declared in Terraform. By deploying this code, you have a ready-made environment that aligns with common cloud security best practices.

Architecture
VPC + Subnet + Internet Gateway
A single VPC hosting a public subnet for the EC2 instance.
Flow Logs
Captures inbound/outbound network traffic and sends to CloudWatch Logs.
S3 Bucket
Defaults to AES-256 encryption at rest.
Optional bucket policy to enforce encryption and HTTPS connections.
EC2 Instance
Uses an IAM Instance Profile to avoid storing credentials locally.
A Security Group restricts inbound traffic to specific CIDRs (or 0.0.0.0/0 if testing).
Prerequisites
AWS Account with permissions to create VPCs, subnets, security groups, EC2, S3, IAM, and CloudWatch Logs.
Terraform (version 1.x or newer).
AWS CLI (optional, but helpful for validation).
Installation and Setup
Clone the Repo
bash
Copy code
git clone https://github.com/peretzrickett/deloitte1.git
cd deloitte1
Configure AWS Credentials
Run:
bash
Copy code
aws configure
Provide an AWS Access Key, Secret Access Key, default region, and output format.
Or set environment variables like AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
Deployment
Initialize Terraform
bash
Copy code
terraform init
Installs required providers (e.g., AWS).
Sets up the local Terraform environment.
Plan and Apply
Review the Plan

bash
Copy code
terraform plan
Shows which resources will be created, modified, or destroyed.
Deploy Resources

bash
Copy code
terraform apply
Type yes when prompted.
Terraform then creates the VPC, subnets, S3 bucket, EC2 instance, etc.
Verification
After a successful deployment, check the AWS Console:

VPC:
Confirm a Flow Log is active for the VPC.
See logs in CloudWatch Logs under /aws/vpc/flow-logs/....
S3:
Access the newly created bucket to confirm Default Encryption is set.
If using a bucket policy, confirm encryption is enforced.
EC2:
Ensure the instance is running in the VPC’s public subnet.
Confirm the IAM Role is attached (visible on the EC2 → Actions → Security → Modify IAM Role page).
Security Group: confirm only the configured CIDR (or 0.0.0.0/0 for testing) can connect via port 22.
Outputs
You can run:

bash
Copy code
terraform output
to see:

vpc_id: The ID of the created VPC.
s3_bucket_name: The name of the secure S3 bucket.
ec2_public_ip: The public IP address of the EC2 instance.
Teardown
To avoid ongoing AWS costs, destroy the environment once done:

bash
Copy code
terraform destroy
Type yes to confirm.
Terraform will remove all resources, including the VPC, S3 bucket (must be empty), and IAM roles.
NIST CSF Mapping
NIST CSF	AWS Control	Resource
PR.PT-1	VPC Flow Logs for audit, stored in CloudWatch Logs	aws_flow_log.vpc_flow_logs
PR.DS-1	S3 Bucket with server-side encryption	aws_s3_bucket.secure_bucket
PR.AC-3	EC2 IAM Role (no embedded creds) + restrictive SG	aws_instance.ec2_instance & aws_security_group.ec2_sg
Notes and Warnings
0.0.0.0/0 for SSH: Not recommended for production; it allows all IPs to connect over SSH.
S3 Bucket Deletion: If the bucket contains objects, Terraform destroy may fail. Remove or empty the bucket first.
Deprecation Warning: If you see references to log_group_name being deprecated, replace it with log_destination referencing the CloudWatch Log Group ARN.
Costs: Standard AWS charges apply for the running EC2 instance, Flow Logs storage, and other resources.