
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.00"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  publish = true
  function_name = "test-update-function-code"
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  source_path = "./src"

  tags = {
    Owner = "Chris-Wang-SE"
    Project = "demo"
  }
}