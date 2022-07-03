variable "name" {}
variable "vpc_id" {}
variable "port" {}
variable "cidr_blocks" {
  type = list(string) // この設定をすることで指定以外の値が渡るとエラーとして落ちるようにしている
}

resource "aws_security_group" "demo" {
  name   = var.name
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  from_port         = var.port
  protocol          = "tcp"
  security_group_id = aws_security_group.demo.id
  to_port           = var.port
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.demo.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "security_group_id" {
  value = aws_security_group.demo.id
}