output "app_endpoint" {
  value       = "http://${kubernetes_ingress_v1.app_ingress.status.0.load_balancer.0.ingress.0.hostname}/healthcheck"
  description = "URL de Health Check da aplicação."
}