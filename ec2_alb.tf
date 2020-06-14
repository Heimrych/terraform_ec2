##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "us-east-1"
}
variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.1.0.0/24"
}
variable "subnet2_address_space" {
  default = "10.1.1.0/24"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block           = var.network_address_space
  enable_dns_hostnames = "true"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet1" {
  cidr_block              = var.subnet1_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[0]

}

resource "aws_subnet" "subnet2" {
  cidr_block              = var.subnet2_address_space
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[1]

}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rta-subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rtb.id
}

# SECURITY GROUPS #
resource "aws_security_group" "elb-sg" {
  name   = "nginx_elb_sg"
  vpc_id = aws_vpc.vpc.id

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Nginx security group 
resource "aws_security_group" "nginx-sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.vpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.network_address_space]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "alb_front" {
	name		=	"front-alb"
	internal	=	false
  load_balancer_type = "application"
	security_groups	=	[aws_security_group.elb-sg.id]
	subnets		=	[aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_alb_listener" "alb_listener" {  
  load_balancer_arn = aws_alb.alb_front.arn
  port              = 80 
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = aws_alb_target_group.alb_front_https.arn
    type             = "forward"  
  }
}

resource "aws_alb_target_group" "alb_front_https" {
	name	= "alb-front-https"
	vpc_id	= aws_vpc.vpc.id
	port	= 80
	protocol	= "HTTP"
}

resource "aws_alb_target_group_attachment" "alb_nginx_http" {
  target_group_arn = aws_alb_target_group.alb_front_https.arn
  target_id        = aws_instance.nginx.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "alb_apache_http" {
  target_group_arn = aws_alb_target_group.alb_front_https.arn
  target_id        = aws_instance.apache.id
  port             = 80
}

# INSTANCES #
resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  user_data               = <<-EOF
                          #!/bin/bash
                          sudo su
                          yum -y install nginx
                          echo "<p> My NGINX Instance! </p>" >> /usr/share/nginx/html/index.html
                          sudo systemctl enable nginx
                          sudo systemctl start nginx
                          EOF
}

resource "aws_instance" "apache" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  user_data               = <<-EOF
                          #!/bin/bash
                          sudo su
                          yum -y install httpd
                          echo "<p> My APACHE Instance! </p>" >> /var/www/html/index.html
                          sudo systemctl enable httpd
                          sudo systemctl start httpd
                          EOF
}

##################################################################################
# OUTPUT
##################################################################################

output "aws_elb_public_dns" {
  value = aws_alb.alb_front.dns_name
}
