output "vpc_id" {
  value = aws_vpc.main.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.secure_bucket.bucket
}

output "ec2_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}
