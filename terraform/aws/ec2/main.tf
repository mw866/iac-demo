terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a vpc
resource "aws_vpc" "cspmVpc"{
    cidr_block = "10.0.0.0/16"
}

# Create an internet gateway
resource "aws_internet_gateway" "cspmGateway" {
  vpc_id = aws_vpc.cspmVpc.id
}

# Configure route table
resource "aws_route_table" "cspmRouteTable" {
  vpc_id = aws_vpc.cspmVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cspmGateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.cspmGateway.id
  }
}

# Configure a subnet
resource "aws_subnet" "cspmSubnet1"{
    vpc_id = aws_vpc.cspmVpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
}

# Assign subnet to route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.cspmSubnet1.id
  route_table_id = aws_route_table.cspmRouteTable.id
}

# Create security group
resource "aws_security_group" "cspm_allow_web" {
  name        = "allow_web"
  description = "Allow Web Inbound Traffic"
  vpc_id      = aws_vpc.cspmVpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create network interface
resource "aws_network_interface" "cspmWebServer" {
  subnet_id       = aws_subnet.cspmSubnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.cspm_allow_web.id]
}

# Assign an elastic ip to the network interface
resource "aws_eip" "cspm_eip" {
  vpc                       = true
  network_interface         = aws_network_interface.cspmWebServer.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.cspmGateway]
}

# Configure ec2 resource
resource "aws_instance" "cspmInstance" {
  ami = "ami-08a52ddb321b32a8c"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_role.cspm_full_access_role.name
  disable_api_termination = false

  availability_zone = "us-east-1a"
  key_name = "cspmKey"

  network_interface{
    device_index = 0
    network_interface_id = aws_network_interface.cspmWebServer.id
  }

  provisioner "file" {
    source      = "./sensitive-data.txt"  # Path to your local credentials file
    destination = "/path/to/credentials.txt"  # Destination path on the EC2 instance
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemct1 start apache2
              sudo bash -c 'echo cspm test > /var/wwww/html/index.html'
              EOF  
}

# Create EBS volume
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.cspm_ebs_volume.id
  instance_id = aws_instance.cspmInstance.id
}

resource "aws_ebs_volume" "cspm_ebs_volume" {
  availability_zone = "us-east-1a"
  size              = 1
  encrypted         = false
}


# Create IAM role for EC2 instance with full access
resource "aws_iam_role" "cspm_full_access_role" {
  name = "example-ec2-instance-role"

  assume_role_policy = jsonencode({
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

# Attach a policy that grants full access to EC2 instance
resource "aws_iam_role_policy_attachment" "cspm_full_access_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"  # Full access to EC2

  role = aws_iam_role.cspm_full_access_role.name
}


# Create a Network ACL for the subnet
resource "aws_network_acl" "cspm_subnet_acl" {
  vpc_id = aws_vpc.cspmVpc.id
}

# Add a custom Network ACL entry to allow ingress from 0.0.0.0/0 (any IP)
resource "aws_network_acl_rule" "cspm_subnet_acl_ingress" {
  network_acl_id = aws_network_acl.cspm_subnet_acl.id
  rule_number    = 100  # Adjust the rule number to avoid conflicts with existing rules

  egress          = false  # Set to true for egress rules, false for ingress rules
  protocol        = "6"    # TCP protocol (can be "6" for TCP, "17" for UDP, "-1" for all)
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"  # Allow any source IP (0.0.0.0/0) to access the subnet
  from_port       = 0
  to_port         = 65535
}

# Add a custom Network ACL entry to allow egress to 0.0.0.0/0 (any IP)
resource "aws_network_acl_rule" "cspm_subnet_acl_egress" {
  network_acl_id = aws_network_acl.cspm_subnet_acl.id
  rule_number    = 200  # Adjust the rule number to avoid conflicts with existing rules

  egress          = true  # Set to true for egress rules, false for ingress rules
  protocol        = "-1"  # All protocols (-1) for egress rule
  rule_action     = "allow"
  cidr_block      = "0.0.0.0/0"  # Allow any destination IP (0.0.0.0/0) from the subnet
  from_port       = 0
  to_port         = 0
}
