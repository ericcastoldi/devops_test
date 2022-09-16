variable "env" {
  default     = "test"
  description = "Nome do ambiente. Utilizado para marcar com tags todos os recursos de infra."
}

variable "cluster_name" {
  default = "get-ninjas-devops-test"
}

variable "openid_connect_provider_arn" {
  description = "ARN do OpenID Connect Provider."
}


variable "openid_connect_provider_url" {
  description = "URL do OpenID Connect Provider."
}