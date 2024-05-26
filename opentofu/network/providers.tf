terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "tinker-tech-network-tf-state"
    key     = "network.tfstate"
    profile = "network"
    region  = "eu-west-2"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "network"
}
