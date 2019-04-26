provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "default" {
  bucket = "demo-cicd-python"
  acl    = "private"
}

resource "aws_iam_role" "iam_codebuild_role" {
  name = "iam_codebuild_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "iam_codebuild_policy" {
  name = "iam_codebuild_policy"
  role = "${aws_iam_role.iam_codebuild_role.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.default.arn}",
        "${aws_s3_bucket.default.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "codebuild_test" {
  name          = "test-project"
  description   = "test_codebuild_project"
  build_timeout = "5"
  service_role  = "${aws_iam_role.iam_codebuild_role.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.default.bucket}"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/python:3.7.1-1.7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      "name"  = "SOME_KEY1"
      "value" = "SOME_VALUE1"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/duy0611/python-cicd-terraform.git"
    git_clone_depth = 1
  }

  tags = {
    "Environment" = "Test"
  }
}
