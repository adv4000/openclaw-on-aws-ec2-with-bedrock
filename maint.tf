#----------------------------------------------------------
# OpenClaw on EC2 AmazonLinux and AWS Bedrock Models
#
# Made by Denis Astahov
#----------------------------------------------------------

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Owner   = "Denis Astahov"
      Company = "ADV-IT"
      Project = "OpenClaw"
    }
  }
}

data "aws_ami" "latest_amazonlinux" {
  owners      = ["137112412989"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

resource "random_string" "token" {
  length  = 32
  special = false
}

resource "aws_instance" "openclaw" {
  ami                         = data.aws_ami.latest_amazonlinux.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.this.name
  vpc_security_group_ids      = [aws_security_group.openclaw.id]
  key_name                    = var.ssh_key_name
  user_data_replace_on_change = true

  user_data = templatefile("user_data.sh", {
    aws_region       = var.aws_region
    openclaw_port    = var.openclaw_port
    openclaw_model   = var.openclaw_model
    openclaw_version = var.openclaw_version
    openclaw_token   = random_string.token.result
  })

  root_block_device {
    volume_size = var.instance_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "OpenClaw" }
}

resource "aws_security_group" "openclaw" {
  name        = "OpenClaw-SG"
  description = "Security Group for OpenClaw"
  tags        = { Name = "OpenClaw SG" }
}

resource "aws_vpc_security_group_egress_rule" "openclaw" {
  security_group_id = aws_security_group.openclaw.id
  description       = "Allow ALL"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_vpc_security_group_ingress_rule" "openclaw" {
  security_group_id = aws_security_group.openclaw.id
  description       = "Allow SSH"
  cidr_ipv4         = "${chomp(data.http.my_ip.response_body)}/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# IAM Role
resource "aws_iam_role" "this" {
  name = "OpenClaw-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock" {
  count      = var.enable_poweruser ? 0 : 1
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_poweruser ? 0 : 1
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "poweruser" {
  count      = var.enable_poweruser ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_instance_profile" "this" {
  name = "OpenClaw-Profile"
  role = aws_iam_role.this.name
}
