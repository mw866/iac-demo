
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.10.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Owner   = "Chris-Wang-SE"
      Project = "demo"
    }
  }
}

variable "name" {
  type    = string
  default = "sagemaker-notebook-demo"
}

resource "aws_sagemaker_notebook_instance" "notebook_instance_demo" {
  name          = var.name
  role_arn      = aws_iam_role.notebook_instance_demo.arn
  instance_type = "ml.t2.medium"
}


resource "aws_iam_role" "notebook_instance_demo" {
  name               = var.name
  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "sagemaker.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
    }
    EOF
}

output "presigned_URL_command" {
  value = "Generate the presigned URL with this command: \n aws sagemaker create-presigned-notebook-instance-url --notebook-instance-name ${aws_sagemaker_notebook_instance.notebook_instance_demo.name}"
}
