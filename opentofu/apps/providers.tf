terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "tinker-tech-apps-tf-state"
    key     = "apps.tfstate"
    profile = "apps"
    region  = "eu-west-2"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "apps"
}
