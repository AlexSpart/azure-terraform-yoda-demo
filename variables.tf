variable "resource_group_name" {
  type    = string
  default = "spartdemo"
}

variable "resource_group_location" {
  type    = string
  default = "norwayeast"
}

# variable "key_vault_name" {
#   type    = string
#   default = "CHANGEME-kv"
# }

# variable "container_registry_name" {
#   type    = string
#   default = "CHANGEME"
# }

# variable "log_analytics_workspace_name" {
#   type    = string
#   default = "CHANGEME-la"
# }

variable "virtual_network_name" {
  type    = string
  default = "yoda-cookie-vnet"
}

variable "kubernetes_cluster_name" {
  type    = string
  default = "yoda-cookie-aks"
}

variable "public_ip_name" {
  type    = string
  default = "yoda-cookie-ip"
}

variable "application_gateway_name" {
  type    = string
  default = "yoda-cookie-appgateway"
}

variable "resources_location" {
  type    = string
  default = "norwayeast"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Terraform Managed"
    Owner       = "Alexandros Spartalis"
  }
}

