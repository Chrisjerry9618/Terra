provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAU65TGYDCJ3IAFHWJ"
  secret_key = "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"
}
variable "aws_public_subnet_1a" {
  type = "string"
  default = "us-east-1a"
}
variable "aws_public_subnet_1b" {
  type = "string"
  default = "us-east-1b"
}
variable "aws_public_subnet_1c" {
  type = "string"
  default = "us-east-1c"
}
variable "aws_private_subnet_1a" {
  type = "string"
  default = "us-east-1a"
}
resource "aws_vpc" "chris-test" {
   cidr_block = "10.0.0.0/16"

    tags = {
    Name = "chris-test"
  }
}
resource "aws_internet_gateway" "chris-igw" {
  vpc_id = "${aws_vpc.chris-test.id}"

  tags = {
    Name = "chris-igw"
  }
}
resource "aws_subnet" "public-subnet" {
   vpc_id     = "${aws_vpc.chris-test.id}"
   cidr_block = "10.0.1.0/24"
   map_public_ip_on_launch = "true"
   availability_zone = "${var.aws_public_subnet_1a}"
    
   tags = { Name = "chris-test-subnet1" }
}
resource "aws_subnet" "public-subnet2"{
   vpc_id     = "${aws_vpc.chris-test.id}"
   cidr_block = "10.0.2.0/24"
   map_public_ip_on_launch = "true"
   availability_zone = "${var.aws_public_subnet_1b}"


   tags = { Name = "chris-test-subnet2" }
}
resource "aws_subnet" "public-subnet3"{
   vpc_id     = "${aws_vpc.chris-test.id}"
   cidr_block = "10.0.3.0/24"
   map_public_ip_on_launch = "true"
   availability_zone = "${var.aws_public_subnet_1c}"


   tags = { Name = "chris-test-subnet3" }
}
resource "aws_subnet" "private-subnet1"{
   vpc_id     = "${aws_vpc.chris-test.id}"
   cidr_block = "10.0.4.0/24"
   map_public_ip_on_launch = "true"
   availability_zone = "${var.aws_private_subnet_1a}"


   tags = { Name = "chris-test-subnet4" }
}
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.chris-test.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.chris-igw.id}"
  }
  tags = {
    Name = "main"
  }
}
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.chris-test.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.chris-igw.id}"
  }
  tags = {
    Name = "private-route"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.r.id}"
}
resource "aws_route_table_association" "b" {
  subnet_id      = "${aws_subnet.public-subnet2.id}"
  route_table_id = "${aws_route_table.r.id}"
}
resource "aws_route_table_association" "c" {
  subnet_id      = "${aws_subnet.public-subnet3.id}"
  route_table_id = "${aws_route_table.r.id}"
}
resource "aws_route_table_association" "1" {
  subnet_id      = "${aws_subnet.private-subnet1.id}"
  route_table_id = "${aws_route_table.private.id}"
}
resource "aws_security_group" "sg" {
  name        = "web-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.chris-test.id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["183.82.251.22/32", "52.76.93.21/32", "122.178.32.72/32"] # add a CIDR block here
  }
ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["183.82.251.22/32",  "52.76.93.21/32", "122.178.32.72/32"] # add a CIDR block here
  }
ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["122.178.42.131/32"] # add a CIDR block here
  }

ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["122.178.42.131/32"] # add a CIDR block here
 }
}
resource "aws_instance" "ec2" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  key_name = "chrisaws"
  instance_type = "t2.micro"
  ami = "ami-04b9e92b5572fa0d1"
  vpc_security_group_ids = ["${aws_security_group.sg.id}"]
}
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.sg.id}"]
  subnets            = ["${aws_subnet.public-subnet.id}", "${aws_subnet.public-subnet2.id}"]

  tags = {
    Environment = "production"
  }
}resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.test.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.target.arn}"
  }
}
resource "aws_lb_target_group" "target" {
  name     = "test-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.chris-test.id}"
}

resource "aws_lb_target_group_attachment" "register" {
  target_group_arn = "${aws_lb_target_group.target.arn}"
  target_id        = "${aws_instance.ec2.id}"
  port             = 80
}
