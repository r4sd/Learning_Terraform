variable "example_instance_type" {
  default = "t3.micro"
}

// インスタンス設定
resource "aws_instance" "demo" {
  ami                  = "ami-0b7546e839d7ace12"
  instance_type        = var.example_instance_type
  user_data            = file("./userdata/setup.sh")
  iam_instance_profile = "SSMTest"
  subnet_id            = "subnet-05b75876bd5169df1"
}

//ネットワーク周り
resource "aws_vpc" "demo" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo"
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.demo.id
  destination_cidr_block = "0.0.0.0/0"
}
//============↑multiple化設定変更でいじらなかったものら===============

//Public subnet multiple AZ
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
}
//============================================

//Public subnetとRoute tableの関連付け
resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
//==============================================

//Private Network Settings
//Subnet
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.10.32.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.10.33.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
}
//==============================================

//NATゲートウェイ multiple AZ
resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.demo]
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.demo]
}

resource "aws_nat_gateway" "nat_gateway_0" {
  subnet_id     = aws_subnet.public_0.id
  allocation_id = aws_eip.nat_gateway_0.id
  depends_on    = [aws_internet_gateway.demo]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  subnet_id     = aws_subnet.public_1.id
  allocation_id = aws_eip.nat_gateway_1.id
  depends_on    = [aws_internet_gateway.demo]
}
//==============================================

//Route table
resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.demo.id
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  route_table_id = aws_route_table.private_1.id
  subnet_id      = aws_subnet.private_0.id
}

resource "aws_route_table_association" "private_1" {
  route_table_id = aws_route_table.private_1.id
  subnet_id      = aws_subnet.private_1.id
}
//==============================================


//セキュリティ設定（FW）
resource "aws_security_group" "demo" {
  name   = "demo"
  vpc_id = aws_vpc.demo.id
}

resource "aws_security_group_rule" "ingress_demo" {
  from_port         = "80"
  protocol          = "tcp"
  security_group_id = aws_security_group.demo.id
  to_port           = "80"
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_demo" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.demo.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "demo_sg" {
  source      = "./sg"
  name        = "module_sg"
  vpc_id      = aws_vpc.demo.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}
/*
修正前のコードは以下の通り
resource "aws_security_group" "demo1" {
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
*/

resource "aws_lb" "demo" {
  name               = "demo"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 60
  //enable_deletion_protection = false //  学習中なので消えてもOK

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}
module "http_sg" {
  source      = "./sg"
  name        = "http_sg"
  vpc_id      = aws_vpc.demo.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./sg"
  name        = "https_sg"
  vpc_id      = aws_vpc.demo.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./sg"
  name        = "http_redirect_sg"
  vpc_id      = aws_vpc.demo.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.demo.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is [HTTP]"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.demo.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.demo.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is [HTTPS]"
      status_code  = "200"
    }
  }
}

data "aws_route53_zone" "demo" {
  name = "c16e-dev.com"
}

resource "aws_route53_zone" "demo" {
  name = "demo.c16e-dev.com"
}

resource "aws_route53_record" "demo" {
  name    = data.aws_route53_zone.demo.name
  type    = "A"
  zone_id = data.aws_route53_zone.demo.id

  alias {
    evaluate_target_health = true
    name                   = aws_lb.demo.dns_name
    zone_id                = aws_lb.demo.zone_id
  }
}

resource "aws_acm_certificate" "demo" {
  domain_name               = aws_route53_record.demo.name
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_route53_record" "demo_certificate" {
  name    = aws_acm_certificate.demo.domain_validation_options.
  type    = aws_acm_certificate.demo.domain_validation_options.resource_record_type
  zone_id = data.aws_route53_zone.demo.id
  ttl     = 60
  records = [aws_acm_certificate.demo.domain_validation_options.resource_record_value]
}

resource "aws_acm_certificate_validation" "demo" {
  certificate_arn         = aws_acm_certificate.demo.arn
  validation_record_fqdns = [aws_route53_record.demo_certificate.fqdn]
}
*/

resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.demo.arn
  port              = "8080"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

output "instance_id" {
  value = aws_instance.demo.id
}

output "public_dns" {
  value = aws_instance.demo.public_dns
}

output "alb_dns_name" {
  value = aws_lb.demo.dns_name
}

output "domain_name" {
  value = aws_route53_record.demo.name
}