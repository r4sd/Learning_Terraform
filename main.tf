variable "example_instance_type" {
  default = "t3.micro"
}

resource "aws_instance" "default" {
  ami                  = "ami-0b7546e839d7ace12"
  instance_type        = var.example_instance_type
  user_data            = file("./userdata/setup.sh")
  iam_instance_profile = "SSMTest"
  subnet_id            = aws_subnet.public.id
}

resource "aws_security_group" "default" {
  name = "ec2"
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "default" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "default"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.default.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.10.32.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private.id
}

resource "aws_eip" "nat_gateway" {
  vpc        = true
  depends_on = [aws_internet_gateway.default]
}

resource "aws_nat_gateway" "public" {
  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.nat_gateway.id
  depends_on    = [aws_internet_gateway.default]
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.public.id
  destination_cidr_block = "0.0.0.0/0"
}

output "instance_id" {
  value = aws_instance.default.id
}

output "public_dns" {
  value = aws_instance.default.public_dns
}
