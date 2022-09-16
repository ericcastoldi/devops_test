output "cluster_iam_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "fargate_profile_iam_role_arn" {
  value = aws_iam_role.eks_fargate_profile.arn
}

output "load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller_role.arn
}