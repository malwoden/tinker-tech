terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
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

data "aws_eks_cluster" "apps" {
  name       = "apps-cluster"
  depends_on = [aws_eks_cluster.apps_cluster]
}

data "aws_eks_cluster_auth" "apps" {
  name       = "apps-cluster"
  depends_on = [aws_eks_cluster.apps_cluster]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.apps.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.apps.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.apps.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.apps.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.apps.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.apps.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.apps.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.apps.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.apps.token
  load_config_file       = false
}
