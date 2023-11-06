terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Owner   = "Chris-Wang-SE"
      Project = "demo"
    }
  }

}

variable "prefix" {
  default = "aws-ami-demo"
  type    = string

}

resource "aws_instance" "original_instance" {
  # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.nano"
  tags = {
    Name = "${var.prefix}-orignal-builder"
  }

}

resource "aws_ami_from_instance" "original_ami" {
  name               = "${var.prefix}-orignal"
  source_instance_id = aws_instance.original_instance.id
}


resource "aws_instance" "malicious_builder_instance" {
  ami           = aws_ami_from_instance.original_ami.id
  instance_type = "t2.nano"
  tags = {
    Name = "${var.prefix}-malicious-builder"
  }
  user_data = <<-EOF
              #!/bin/bash
              wget https://secure.eicar.org/eicar.com
              EOF  
}

resource "aws_ami_from_instance" "malicious_ami" {
  name               = "${var.prefix}-malicious"
  source_instance_id = aws_instance.original_instance.id
}

resource "aws_instance" "malicious_runner_instance" {
  ami           = aws_ami_from_instance.malicious_ami.id
  instance_type = "t2.nano"
  tags = {
    Name = "${var.prefix}-malicious-runner"
  }
}
