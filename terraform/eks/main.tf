resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.cluster_iam_role_arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)
  }

  #depends_on = [aws_iam_role_policy_attachment.amazon-eks-cluster-policy]
}


# Fargate
resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = var.fargate_profile_iam_role_arn

  subnet_ids = var.private_subnet_ids

  selector {
    namespace = "kube-system"
  }
}

resource "aws_eks_fargate_profile" "app" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = var.env
  pod_execution_role_arn = var.fargate_profile_iam_role_arn

  subnet_ids = var.private_subnet_ids

  selector {
    namespace = var.env
  }
}

data "tls_certificate" "eks_cert" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.cluster.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.cluster.id
}

resource "null_resource" "k8s_patcher" {
  depends_on = [aws_eks_fargate_profile.kube-system]

  triggers = {
    endpoint = data.aws_eks_cluster.cluster.endpoint
    ca_crt   = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    token    = data.aws_eks_cluster_auth.cluster.token
  }

  provisioner "local-exec" {
    command = <<EOH
cat >/tmp/ca.crt <<EOF
${base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)}
EOF
kubectl \
  --server="${aws_eks_cluster.cluster.endpoint}" \
  --certificate-authority=/tmp/ca.crt \
  --token="${data.aws_eks_cluster_auth.cluster.token}" \
  patch deployment coredns \
  -n kube-system --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
EOH
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# K8s
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  #  config_path = "~/.kube/config"
}


# K8s - Ingress Config


# K8s - App Deploy
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.env
    labels = {
      app = var.app_name
    }
  }

  depends_on = [aws_eks_fargate_profile.app]
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "${var.app_name}-deployment"
    namespace = var.env
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          image = var.app_image
          name  = var.app_name

          port {
            container_port = var.app_port
          }
        }
      }
    }
  }
  depends_on = [kubernetes_namespace.app_namespace]
}
