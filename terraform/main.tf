# TODO: Refatorar subnets e todos os outros recursos de rede que estão sendo criados de forma duplicada. Utilizar maps e for_eachs. Exemplo - https://engineering.finleap.com/posts/2020-02-20-ecs-fargate-terraform/#vpc

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
  }
}

provider "aws" {
  region = "us-east-1"
}


# ------------ VPC ---------------

locals {
  app_env_description = "${var.app_name} (${var.env})"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "Main VPC - ${local.app_env_description}"
  }
}

resource "aws_subnet" "private-us-east-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    App                                         = var.app_name
    Env                                         = var.env
    Name                                        = "Private Subnet 1 - ${var.app_name} (${var.env})"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

resource "aws_subnet" "private-us-east-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    App                                         = var.app_name
    Env                                         = var.env
    Name                                        = "Private Subnet 2 - ${local.app_env_description}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }
}

resource "aws_subnet" "public-us-east-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    App                                         = var.app_name
    Env                                         = var.env
    Name                                        = "Public Subnet 1 - ${local.app_env_description}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }
}

resource "aws_subnet" "public-us-east-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    App                                         = var.app_name
    Env                                         = var.env
    Name                                        = "Public Subnet 2 - ${local.app_env_description}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "Internet Gateway - ${local.app_env_description}"
  }
}

resource "aws_eip" "nat_1a" {
  vpc = true

  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "NAT Elastic IP 1 - ${local.app_env_description}"
  }
}


# resource "aws_eip" "nat_1b" {
#   vpc = true

#   tags = {
#     App = var.app_name
#     Env = var.env
#     Name = "NAT Elastic API 2 - ${local.app_env_description}"
#   }
# }

resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.public-us-east-1a.id


  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "NAT Gateway 1 - ${local.app_env_description}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# resource "aws_nat_gateway" "nat_1b" {
#   allocation_id = aws_eip.nat_1b
#   subnet_id     = aws_subnet.public-us-east-1b.id


#   tags = {
#     App = var.app_name
#     Env = var.env
#     Name = "NAT Gateway 2 - ${local.app_env_description}"
#   }

#   depends_on = [aws_internet_gateway.igw]
# }

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }

  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "Private Route Table - ${local.app_env_description}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    App  = var.app_name
    Env  = var.env
    Name = "Public Route Table - ${local.app_env_description}"
  }
}

resource "aws_route_table_association" "private-us-east-1a" {
  subnet_id      = aws_subnet.private-us-east-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-us-east-1b" {
  subnet_id      = aws_subnet.private-us-east-1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-us-east-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.public.id
}

# -------- EKS -------------

resource "aws_iam_role" "eks-cluster" {
  name = "eks-cluster-${var.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks-cluster.arn

  vpc_config {

    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    subnet_ids = [
      aws_subnet.private-us-east-1a.id,
      aws_subnet.private-us-east-1b.id,
      aws_subnet.public-us-east-1a.id,
      aws_subnet.public-us-east-1b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.amazon-eks-cluster-policy]
}


# resource "aws_eks_cluster" "eks_cluster" {
#   name = "${var.cluster_name}-${var.env}"

#   role_arn                  = aws_iam_role.eks_cluster_role.arn
#   enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]


#   vpc_config {
#     subnet_ids = concat(var.public_subnets, var.private_subnets)
#   }

#   timeouts {
#     delete = "30m"
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.AmazonEKSClusterPolicy1,
#     aws_iam_role_policy_attachment.AmazonEKSVPCResourceController1,
#     aws_cloudwatch_log_group.cloudwatch_log_group
#   ]
# }

# resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
#   name   = "AmazonEKSClusterCloudWatchMetricsPolicy"
#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": [
#                 "cloudwatch:PutMetricData"
#             ],
#             "Resource": "*",
#             "Effect": "Allow"
#         }
#     ]
# }
# EOF
# }


# resource "aws_iam_role" "eks_cluster_role" {
#   name                  = "${var.cluster_name}-cluster-role"
#   description           = "Allow cluster to manage node groups, fargate nodes and cloudwatch logs"
#   force_detach_policies = true
#   assume_role_policy    = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": [
#           "eks.amazonaws.com",
#           "eks-fargate-pods.amazonaws.com"
#           ]
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy1" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks_cluster_role.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
#   policy_arn = aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn
#   role       = aws_iam_role.eks_cluster_role.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController1" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
#   role       = aws_iam_role.eks_cluster_role.name
# }

# resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
#   name              = "/aws/eks/${var.cluster_name}-${var.environment}/cluster"
#   retention_in_days = 30

#   tags = {
#     Name = "${var.cluster_name}-${var.environment}-eks-cloudwatch-log-group"
#   }
# }

# resource "aws_eks_fargate_profile" "eks_fargate" {
#   cluster_name           = aws_eks_cluster.eks_cluster.name
#   fargate_profile_name   = "${var.cluster_name}-${var.environment}-fargate-profile"
#   pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn
#   subnet_ids             = var.private_subnets

#   selector {
#     namespace = var.fargate_namespace
#   }



#   timeouts {
#     create = "30m"
#     delete = "30m"
#   }
# }

# resource "aws_iam_role" "eks_fargate_role" {
#   name                  = "${var.cluster_name}-fargate_cluster_role"
#   description           = "Allow fargate cluster to allocate resources for running pods"
#   force_detach_policies = true
#   assume_role_policy    = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": [
#           "eks.amazonaws.com",
#           "eks-fargate-pods.amazonaws.com"
#           ]
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
#   role       = aws_iam_role.eks_fargate_role.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks_fargate_role.name
# }


# resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
#   role       = aws_iam_role.eks_fargate_role.name
# }



# resource "aws_eks_node_group" "eks_node_group" {
#   cluster_name    = aws_eks_cluster.eks_cluster.name
#   node_group_name = "${var.cluster_name}-${var.environment}-node_group"
#   node_role_arn   = aws_iam_role.eks_node_group_role.arn
#   subnet_ids      = var.public_subnets

#   scaling_config {
#     desired_size = 2
#     max_size     = 3
#     min_size     = 2
#   }

#   instance_types = ["${var.eks_node_group_instance_types}"]

#   depends_on = [
#     aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
#   ]
# }

# resource "aws_iam_role" "eks_node_group_role" {
#   name = "${var.cluster_name}-node-group_role"

#   assume_role_policy = jsonencode({
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#     Version = "2012-10-17"
#   })
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_node_group_role.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_node_group_role.name
# }

# resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_node_group_role.name
# }

# data "tls_certificate" "auth" {
#   url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "main" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.auth.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
# }

