provider "aws" {
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "project_name" {
  default = "example"
}

resource "aws_s3_bucket" "source" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.project_name}-source"
  acl    = "private"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket" "result" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.project_name}-result"
  acl    = "private"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 1
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.project_name}"
          }
        }
      },
    ]
  })
}

// https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html#setting-up-service-role
resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Resource = ["*"]
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = [
          "${aws_s3_bucket.source.arn}",
          "${aws_s3_bucket.source.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
        ]
        Resource = [
          "${aws_s3_bucket.result.arn}",
          "${aws_s3_bucket.result.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_codebuild_project" "codebuild" {
  name          = var.project_name
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.project_name}-codebuild"
      stream_name = "codebuild"
    }
  }

  # Should be overriden when start-build
  source {
    type     = "S3"
    location = "${aws_s3_bucket.source.arn}/source.zip"
  }
}
