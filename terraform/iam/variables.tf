variable "env" {
  default     = "test"
  description = "Nome do ambiente. Utilizado para marcar com tags todos os recursos de infra."
}

variable "cluster_name" {
  default = "get-ninjas-devops-test"
}