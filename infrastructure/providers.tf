terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82.2"
    }
  }

  backend "s3" {
    bucket         = "eda-tf-states"
    key            = "microsite/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "eda-state-locks"
    encrypt        = true
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = "ap-southeast-2"
}