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

  // Required for Jenkins AWS CodeBuild plugin
  // (optional otherwise)
  versioning {
    enabled = true
  }

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

// https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html#setting-up-service-role
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
        // This cause InvalidInputException: CodeBuild is not authorized to perform: sts:AssumeRole on arn:aws:iam::...
        /*
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.project_name}"
          }
        }
        */
      },
    ]
  })
}

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
          // Required for Jenkins AWS CodeBuild plugin
          // (optional otherwise)
          "s3:GetObjectVersion",
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
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    // https://docs.aws.amazon.com/ja_jp/codebuild/latest/userguide/build-env-ref-available.html
    image                       = "aws/codebuild/standard:5.0"
    // This is required to use docker in codebuild.
    privileged_mode             = true
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-${var.project_name}"
    }
  }

  # Should be overriden when start-build
  source {
    type     = "S3"
    location = "${aws_s3_bucket.source.arn}/source.zip"
  }
}

output "codebuild_project" {
    value = aws_codebuild_project.codebuild.name
}

output "s3_source" {
    value = aws_s3_bucket.source.bucket
}

output "s3_result" {
    value = aws_s3_bucket.result.bucket
}

output "log_group" {
    value = aws_codebuild_project.codebuild.logs_config[0].cloudwatch_logs[0].group_name
}
