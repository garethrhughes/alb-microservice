data "aws_caller_identity" "current" {}

data "aws_vpc" "selected" {
  id = "vpc-095ce73c44ac272f2"
}

data "aws_route53_zone" "hosted_zone" {
  name = "sandbox.mypassglobal.com"
}