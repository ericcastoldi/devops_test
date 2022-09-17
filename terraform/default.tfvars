app_name = "get-ninjas"
app_port = 80
app_image = "ericcastoldi/get-ninjas-api:latest"
app_region = "us-east-1"

env = "prod"
cluster_name = "get-ninjas-cluster"
cluster_version = "1.23"

vpc_cidr = "10.0.0.0/16"
private_subnets = [ {
    az   = "us-east-1a"
    cidr = "10.0.1.0/24"
    },
    {
      az   = "us-east-1b"
      cidr = "10.0.2.0/24"
  } ]

public_subnets = [ {
    az   = "us-east-1a"
    cidr = "10.0.3.0/24"
    },
    {
      az   = "us-east-1b"
      cidr = "10.0.4.0/24"
  } ]