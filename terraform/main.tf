terraform {
  backend "s3" {
    bucket = "get-ninjas-tf-bucket"
    key    = "tf-state"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      version = "~> 2.13.1"
    }

  }
}

provider "aws" {
  region = var.app_region
}

# VPC
module "vpc" {
  source = "./vpc"

  app_name        = var.app_name
  env             = var.env
  cluster_name    = var.cluster_name
  vpc_cidr        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

# IAM
module "iam" {
  source       = "./iam"
  cluster_name = var.cluster_name
}

# EKS
module "eks" {
  source = "./eks"

  env                          = var.env
  cluster_name                 = var.cluster_name
  cluster_version              = var.cluster_version
  cluster_iam_role_arn         = module.iam.cluster_iam_role_arn
  public_subnet_ids            = module.vpc.public_subnet_ids
  private_subnet_ids           = module.vpc.private_subnet_ids
  app_name                     = var.app_name
  app_port                     = var.app_port
  app_image                    = var.app_image
  fargate_profile_iam_role_arn = module.iam.fargate_profile_iam_role_arn
}
