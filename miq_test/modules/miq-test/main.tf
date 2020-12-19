#--------------------------------------------------------------
# variable
#--------------------------------------------------------------

variable "cidr" {
  description = "The CIDR block for the VPC."
}

variable "public_subnets" {
  description = "Comma separated list of subnets"
}

variable "private_subnets" {
  description = "Comma separated list of subnets"
}

variable "name" {
  description = "Name tag, e.g stack"
  default     = "Stack"
}

variable "region" {
}

variable "tag_purpose" {
}


variable "image" {
}

variable "root_volume_size" {
}
variable "root_volume_type" {
}
variable "type" {
}

#--------------------------------------------------------------
# AWS VPC
#--------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = var.name
    Purpose     = var.tag_purpose
  }
}

#--------------------------------------------------------------
# AWS Gateways
#--------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = var.name
    Purpose     = var.tag_purpose
    Function    = "Gateway"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw_main" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat-gw"
    Purpose     = var.tag_purpose
    Function    = "Gateway"
  }
}


#--------------------------------------------------------------
# AWS Subnets
#--------------------------------------------------------------

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets
  availability_zone       = "us-east-1b"

  tags = {
    Name        = "${var.name}-private_subnet"
    Purpose     = var.tag_purpose
    Function    = "Subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.name}-public_subnet"
    Purpose     = var.tag_purpose
    Function    = "Subnet"
  }
}


#--------------------------------------------------------------
# AWS Routing Tables
#--------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name        = "${var.name}-public"
    Purpose     = var.tag_purpose
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_main.id
  }
  tags = {
    Name        = "${var.name}-private"
    Purpose     = var.tag_purpose
  }
  lifecycle {
    ignore_changes = all
  }
}


#--------------------------------------------------------------
# AWS Routing Table Associations
#--------------------------------------------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

#--------------------------------------------------------------
# AWS SG
#--------------------------------------------------------------

resource "aws_security_group" "miq" {
  name        = "miq-sg"
  vpc_id      = aws_vpc.main.id
  
  
  tags = {
    Name        = "miq-sg"
    Purpose     = var.tag_purpose
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.miq.id
}

resource "aws_security_group_rule" "allow_all_inbound" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.miq.id
}

#--------------------------------------------------------------
# AWS EC2 instance
#--------------------------------------------------------------
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  key_name = "miq-test"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "aws_instance" "public_machine" {
  ami                  = "${var.image}"
  instance_type        = "${var.type}"
  ebs_optimized        = "false"
  subnet_id            = aws_subnet.public_subnet.id
  key_name             = aws_key_pair.ssh.key_name
  user_data            = "${file("${path.module}/scripts/userdata.sh")}"

  vpc_security_group_ids = [aws_security_group.miq.id]

  tags = {
    Name        = "public_machine"
    Purpose     = "${var.tag_purpose}"
  }

  root_block_device {
    volume_type = "${var.root_volume_type}"
    volume_size = "${var.root_volume_size}"
  }

  lifecycle {
    ignore_changes = [user_data, subnet_id, ebs_optimized]
  }
}

resource "aws_instance" "private_machine" {
  ami                  = "${var.image}"
  instance_type        = "${var.type}"
  ebs_optimized        = "false"
  subnet_id            = aws_subnet.private_subnet.id
  key_name             = aws_key_pair.ssh.key_name
  user_data            = "${file("${path.module}/scripts/userdata.sh")}"

  vpc_security_group_ids = [aws_security_group.miq.id]

  tags = {
    Name        = "private_machine"
    Purpose     = "${var.tag_purpose}"
  }

  root_block_device {
    volume_type = "${var.root_volume_type}"
    volume_size = "${var.root_volume_size}"
  }

  lifecycle {
    ignore_changes = [user_data, subnet_id, ebs_optimized]
  }
}


#--------------------------------------------------------------
# AWS ELB
#--------------------------------------------------------------

resource "aws_elb" "miq-test" {
  name                        = "miq-test"
  idle_timeout                = 300
  connection_draining         = true
  connection_draining_timeout = 60

  security_groups = [aws_security_group.miq.id]

  subnets = [aws_subnet.public_subnet.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 15
  }

  tags = {
    Name        = "${var.name}-elb"
    Purpose     = "${var.tag_purpose}"
  }
}


resource "aws_elb_attachment" "miq-test-private-instance_attachment" {
  elb      = aws_elb.miq-test.id
  instance = aws_instance.private_machine.id
}