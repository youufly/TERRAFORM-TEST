# ------------------------------------------------------ Groupe de sécurité ---
resource "aws_security_group" "web" {
  name        = "${local.prefixe}-web"
  description = "HTTP public, SSH restreint a IP de administrateur"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH depuis IP d administration UNIQUEMENT"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_admin]
  }

  egress {
    description = "Sortie libre (mises a jour)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.prefixe}-sg-web" }
}

# -------------------------------------------------------------- Instance -----
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 impose
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 10
  }

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update
    apt-get install -y nginx
    echo "<h1>${local.prefixe} - deploye par Terraform</h1>" > /var/www/html/index.html
    systemctl enable --now nginx
  EOT

  tags = { Name = "${local.prefixe}-web" }
}
