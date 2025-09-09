data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Public Instance (Bastion / Monitoring)
resource "aws_instance" "public_bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_a.id
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web_server.id]

  tags = {
    Name = upper("${var.project_name}-BASTION-HOST")
  }
}

# Private Instance A
resource "aws_instance" "private_app_a" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_a.id
  private_ip    = var.private_app_a_ip
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web_server.id]

  tags = {
    Name = upper("${var.project_name}-APP-SERVER-A")
  }
}

# Private Instance B
resource "aws_instance" "private_app_b" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_b.id
  private_ip    = var.private_app_b_ip
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web_server.id]

  tags = {
    Name = upper("${var.project_name}-APP-SERVER-B")
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion_eip" {
  domain = "vpc"

  tags = {
    Name = upper("${var.project_name}-BASTION-EIP")
  }
}

# Associate Elastic IP with Bastion Host
resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.public_bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

# --- Outputs ---

# Output for the Bastion Host's Public IP
output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

# Private Monitoring Instance
resource "aws_instance" "private_monitoring" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_a.id # Placing in private_a subnet
  private_ip    = var.private_monitoring_ip
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web_server.id]

  tags = {
    Name = upper("${var.project_name}-MONITORING-SERVER")
  }
}
