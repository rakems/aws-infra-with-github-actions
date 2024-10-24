
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "us-east-1"
}
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
          "ec2:DescribeImages"
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

data "aws-vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

data "aws_subnet_ids" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_instance" "example" {
  ami                  = "ami-06b21ccaeff8cd686"
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.my_subnet.id
  iam_instance_profile = aws_iam_role.ec2_role_test.name

  tags = {
    Name = "example-instance"
  }
}
