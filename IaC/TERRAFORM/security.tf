resource "aws_security_group" "web_server" {
  name        = upper("${var.project_name}-WEB-SG")
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from my IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
  }

  ingress {
    description = "Allow SSH from within this security group (for internal communication)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Grafana from within this security group"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Prometheus from within this security group"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allow Node Exporter from within this security group"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = upper("${var.project_name}-WEB-SG")
  }
}