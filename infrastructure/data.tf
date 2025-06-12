data "aws_caller_identity" "current" {}

data "aws_vpc" "selected" {
  id = "vpc-08944544c34dcf9ce"
}

data "aws_route53_zone" "hosted_zone" {
  name = "aws.gareth.one"
}