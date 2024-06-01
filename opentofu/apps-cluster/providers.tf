terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "tinker-tech-apps-tf-state"
    key     = "apps-cluster.tfstate"
    profile = "apps"
    region  = "eu-west-2"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "apps"
}

provider "aws" {
  region  = "eu-west-2"
  profile = "network"
  alias   = "network"
}
