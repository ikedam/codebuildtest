# base name for resources.
# 
# S3 Bucket (for source codes): ${account_id}-${project_name}-source
# S3 Bucket (for build results): ${account_id}-${project_name}-result
# IAM Role: ${project_name}-codebuild
# CodeBuild Project: ${project_name}
# CloudWatch Logs Log Group: ${project_name}-codebuild
#
# See also https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
project_name = "codebuildtest"
