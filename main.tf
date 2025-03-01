terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    region = "us-east-1"
    bucket = "fiap-devops-statebucket"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}
