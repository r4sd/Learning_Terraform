variable "name" {}
variable "policy" {}
variable "identifier" {}

resource "aws_iam_role" "demo" {
  assume_role_policy = ""
  name               = var.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
  }

  /*principals {
    type        = "Service"
    identifiers = [var.identifier]
  }*/
}

resource "aws_iam_policy" "demo" {
  policy = var.policy
  name   = var.name
}

resource "aws_iam_role_policy_attachment" "demo" {
  policy_arn = aws_iam_policy.demo.arn
  role       = aws_iam_policy.demo.name
}

output "iam_role_arn" {
  value = aws_iam_role.demo.arn
}

output "iam_role_name" {
  value = aws_iam_policy.demo.name
}