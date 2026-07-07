terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider to use credentials from environment variables
# which HCP Terraform will set dynamically.
provider "aws" {
  region = "us-east-1"
}
