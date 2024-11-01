#1. create IAM role
# ec2_role_test
# firehose_role
# cloudwatch_agent_role
#2. create IAM policy
# ec2_policy_test
# firehose_policy
#3. Attach IAM policy to IAM role
# ec2_attach
# firehose_role_policy_attachment
# cloudwatch_agent_policy
# firehose_lambda_policy
# firehose_lambda_access
# 4. create profile
# ec2_instance_profile
# cloudwatch_agent_profile
# 5. create resource






resource "aws_iam_role" "ec2_role_test" {
  name = "ec2_role_test"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "ec2_policy_test" {
  name = "ec2_policy_test"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "ec2:CreateTags",
          "ec2:DescribeImages",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:DescribeVpcs",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:DescribeSubnets",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role_test.name
  policy_arn = aws_iam_policy.ec2_policy_test.arn
}

# Create a new VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

# Create a new Subnet in the VPC
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  tags = {
    Name = "my_subnet"
  }
}

# Create an Internet Gateway for VPC
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my_route_table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a Security Group
resource "aws_security_group" "my_security_group" {
  name        = "my_security_group"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my_security_group"
  }
}

# Create an IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile_test"
  role = aws_iam_role.ec2_role_test.name
}

# Create the EC2 Instance
resource "aws_instance" "sample_ec2" {
  ami                    = "ami-02db68a01488594c5" # Update the AMI as per your requirement
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.my_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name # Use the instance profile here
  vpc_security_group_ids = [aws_security_group.my_security_group.id]

  tags = {
    Name = "sample_ec2-instance"
  }
  # User data script to install CloudWatch agent
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-cloudwatch-agent
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
              systemctl start amazon-cloudwatch-agent
              EOF
}



























# Role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = var.firehose_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "firehose.amazonaws.com"
      }
    }]
  })
}

# Create Firehose Delivery Stream for EC2 Infrastructure Logs
resource "aws_kinesis_firehose_delivery_stream" "infra_firehose" {
  name        = "infra-firehose"
  destination = "http_endpoint"

  http_endpoint_configuration {
    name       = "splunk-endpoint-infra"
    role_arn   = aws_iam_role.firehose_role.arn
    url        = var.splunk_hec_url
    access_key = var.splunk_hec_access_key

    # Configure buffering options
    buffering_size     = var.buffering_size
    buffering_interval = var.buffering_interval

    # Enable CloudWatch logging
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/infra-firehose"
      log_stream_name = "splunk-delivery-stream-infra"
    }
    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn                   # Firehose role ARN
      bucket_arn         = aws_s3_bucket.firehose-backup-example-bucket.arn # S3 bucket ARN
      compression_format = "GZIP"                                           # Compression format
    }
  }
}

# Create Firehose Delivery Stream for EC2 Application Logs
resource "aws_kinesis_firehose_delivery_stream" "app_firehose" {
  name        = "app-firehose"
  destination = "http_endpoint"

  http_endpoint_configuration {
    name       = "splunk-endpoint-app"
    role_arn   = aws_iam_role.firehose_role.arn
    url        = var.splunk_hec_url
    access_key = var.splunk_hec_access_key

    # Configure buffering options
    buffering_size     = var.buffering_size
    buffering_interval = var.buffering_interval

    # Enable CloudWatch logging
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/app-firehose"
      log_stream_name = "splunk-delivery-stream-app"
    }
    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn                   # Firehose role ARN
      bucket_arn         = aws_s3_bucket.firehose-backup-example-bucket.arn # S3 bucket ARN
      compression_format = "GZIP"                                           # Compression format
    }
  }
}

# CloudWatch Logs Subscription Filter for EC2 Infrastructure Logs
resource "aws_cloudwatch_log_subscription_filter" "infralogs_to_firehose" {
  name            = "infralogs-to-firehose"
  log_group_name  = var.cloudwatch_log_group_infra
  filter_pattern  = "" # Filter pattern to capture infra logs
  destination_arn = aws_kinesis_firehose_delivery_stream.infra_firehose.arn
  role_arn        = aws_iam_role.firehose_role.arn
}

# CloudWatch Logs Subscription Filter for EC2 Application Logs
resource "aws_cloudwatch_log_subscription_filter" "applogs_to_firehose" {
  name            = "applogs-to-firehose"
  log_group_name  = var.cloudwatch_log_group_app
  filter_pattern  = "" # Filter pattern to capture app logs
  destination_arn = aws_kinesis_firehose_delivery_stream.app_firehose.arn
  role_arn        = aws_iam_role.firehose_role.arn
}

# Create S3 bucket for backup (optional)
resource "aws_s3_bucket" "firehose_backup_example_bucket" {
  bucket = var.firehose_bucket_name
}
























# Create CloudWatch Log Group
/* resource "aws_cloudwatch_log_group" "example_log_group" {
  name = "example_log_group"
} */

# Create IAM role for CloudWatch Agent
resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "cloudwatch_agent_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach policy to CloudWatch Agent role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

# Create an IAM Instance Profile for CloudWatch Agent
resource "aws_iam_instance_profile" "cloudwatch_agent_profile" {
  name = "cloudwatch_agent_profile"
  role = aws_iam_role.cloudwatch_agent_role.name
}
