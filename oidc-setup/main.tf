# -----------------------------------------------------------------------------
# This Terraform configuration sets up the AWS OIDC provider for HCP Terraform
# and creates an IAM role that HCP Terraform can assume.
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Variables to make the configuration reusable
variable "hcp_terraform_organization" {
  description = "Your HCP Terraform organization name"
  type        = string
}

variable "aws_account_id" {
  description = "Your AWS account ID"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role to create"
  type        = string
  default     = "hcp-terraform-role"
}

# -----------------------------------------------------------------------------
# Data source: fetch the certificate thumbprint for app.terraform.io
# -----------------------------------------------------------------------------
data "tls_certificate" "hcp_terraform" {
  url = "https://app.terraform.io"
}

# -----------------------------------------------------------------------------
# Resource: OIDC provider for HCP Terraform
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "hcp_terraform" {
  url = "https://app.terraform.io"

  # The client_id_list must include "aws.workload.identity" as the audience
  client_id_list = ["aws.workload.identity"]

  # The thumbprint_list is derived from the certificate
  thumbprint_list = [data.tls_certificate.hcp_terraform.certificates[0].sha1_fingerprint]
}

# -----------------------------------------------------------------------------
# IAM Role: trust policy allowing HCP Terraform to assume this role via OIDC
# -----------------------------------------------------------------------------
resource "aws_iam_role" "hcp_terraform" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.hcp_terraform.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "app.terraform.io:aud" = "aws.workload.identity"
          }
          # Restrict access to runs from your organization and any workspace/project
          # Using StringLike allows wildcards for project and workspace names.
          StringLike = {
            "app.terraform.io:sub" = "organization:${var.hcp_terraform_organization}:project:*:workspace:*:run_phase:*"
          }
        }
      }
    ]
  })

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "HCP Terraform OIDC"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy: permissions needed for the demo (EC2 and S3, etc.)
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "hcp_terraform" {
  name        = "${var.role_name}-policy"
  description = "Policy for HCP Terraform to manage EC2 instances and S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Attach the policy to the role
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "hcp_terraform" {
  role       = aws_iam_role.hcp_terraform.name
  policy_arn = aws_iam_policy.hcp_terraform.arn
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.hcp_terraform.arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role that HCP Terraform can assume"
  value       = aws_iam_role.hcp_terraform.arn
}

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = aws_iam_role.hcp_terraform.name
}
