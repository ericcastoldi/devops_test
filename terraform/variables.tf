
variable "cluster_name" {
  default = "get-ninjas-devops-test"
}

variable "cluster_version" {
  default = "1.23"
}

variable "app_region" {
  default     = "us-east-1"
  description = "Região da AWS em que a infra deve ser criada."
}

variable "app_image" {
  default     = "ericcastoldi/get-ninjas-api:latest"
  description = "Imagem Docker da aplicação."
}

variable "app_port" {
  default     = 80 #00
  description = "Porta exposta pela aplicação."
}

variable "app_name" {
  default     = "get-ninjas"
  description = "Nome do aplicativo. Utilizado para marcar com tags todos os recursos de infra."
}

variable "env" {
  default     = "test"
  description = "Nome do ambiente. Utilizado para marcar com tags todos os recursos de infra."
}