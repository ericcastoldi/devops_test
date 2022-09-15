
variable "cluster_name" {
  default = "get-ninjas-devops-test"
}

variable "cluster_version" {
  default = "1.23"
}

variable "app_name" {
  default     = "get-ninjas"
  description = "Nome do aplicativo. Utilizado para marcar com tags todos os recursos de infra."
}

variable "env" {
  default     = "test"
  description = "Nome do ambiente. Utilizado para marcar com tags todos os recursos de infra."
}