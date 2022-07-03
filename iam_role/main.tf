variable "name" {}
variable "policy" {}
variable "identifier" {}

resource "aws_iam_role" "default" {
  assume_role_policy = ""
  name               = var.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
  }

  principals {
    type        = "Service"
    identifiers = [var.identifier]
  }
}

resource "aws_iam_policy" "default" {
  policy = var.policy
  name   = var.name
}

resource "aws_iam_role_policy_attachment" "default" {
  policy_arn = aws_iam_policy.default.arn
  role       = aws_iam_policy.default.name
}

output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_policy.default.name
}