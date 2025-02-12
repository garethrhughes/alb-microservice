terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82.2"
    }
  }

  backend "s3" {
    bucket         = "mypassglobal-sandbox-acct-terraform"
    key            = "microsite/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "mypassglobal-sandbox-acct-terraform"
    encrypt        = true
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-southeast-2"
}