
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
  default     = 8000
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

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR da VPC que será criada, e onde os recursos da aplicação serão provisionados."
}

variable "private_subnets" {
  type = list(object({
    cidr = string
    az   = string
  }))
  default = [{
    az   = "us-east-1a"
    cidr = "10.0.1.0/24"
    },
    {
      az   = "us-east-1b"
      cidr = "10.0.2.0/24"
  }]
  description = "Lista de Availability Zones e CIDRs para criação das subnets privadas."
}

variable "public_subnets" {
  type = list(object({
    cidr = string
    az   = string
  }))
  default = [{
    az   = "us-east-1a"
    cidr = "10.0.3.0/24"
    },
    {
      az   = "us-east-1b"
      cidr = "10.0.4.0/24"
  }]
  description = "Lista de Availability Zones e CIDRs para criação das subnets publicas."
}