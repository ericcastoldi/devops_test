output "cluster_iam_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "fargate_profile_iam_role_arn" {
  value = aws_iam_role.eks_fargate_profile.arn
}