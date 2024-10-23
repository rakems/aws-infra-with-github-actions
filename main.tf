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

resource "aws_instance" "example" {
  ami                  = "ami-0acc77abdfc7ed5a6"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_role.ec2_role_test.name

  tags = {
    Name = "example-instance"
  }
}
