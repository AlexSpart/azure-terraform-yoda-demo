# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.8"
    }
  }

  required_version = ">= 1.1.0"

# If you use remote backend then you need to set it.
  backend "remote" {
    organization = "spartalis"
    workspaces {
      name = "azure-terraform-demo"
    }
  }
}


provider "azurerm" {
  skip_provider_registration = "true"
  features {
    # key_vault {
    #   purge_soft_delete_on_destroy = true
    # }
  }
}

data "azurerm_client_config" "current" {}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = var.tags

}

# Create key vault
# resource "azurerm_key_vault" "kv" {
#   name                            = var.key_vault_name
#   location                        = var.resources_location
#   resource_group_name             = azurerm_resource_group.rg.name
#   sku_name                        = "standard"
#   tenant_id                       = data.azurerm_client_config.current.tenant_id
#   enabled_for_deployment          = false
#   enabled_for_disk_encryption     = false
#   enabled_for_template_deployment = false
#   soft_delete_retention_days      = 7
#   purge_protection_enabled        = false

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id

#     certificate_permissions = [
#       "Get",
#     ]

#     key_permissions = [
#       "Get",
#     ]

#     secret_permissions = [
#       "Get",
#     ]

#     storage_permissions = [
#       "Get",
#     ]
#   }

#   tags = var.tags

# }

# Create container registry
# resource "azurerm_container_registry" "acr" {
#   name                = var.container_registry_name
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = var.resources_location
#   sku                 = "Premium"
#   admin_enabled       = true
#   retention_policy = [
#     {
#       days    = 7
#       enabled = true
#     },
#   ]
#   zone_redundancy_enabled = false

#   tags = var.tags

# }

# Create log analytics workspace
# resource "azurerm_log_analytics_workspace" "la" {
#   name                = var.log_analytics_workspace_name
#   location            = var.resources_location
#   resource_group_name = azurerm_resource_group.rg.name
#   retention_in_days   = 30

#   tags = var.tags

# }

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.resources_location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = [
    "10.0.0.0/8",
  ]
  dns_servers = []

  tags = var.tags

}

# Create subnet for application gateway
resource "azurerm_subnet" "gateway" {
  name                 = "appgateway"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/16"]
}

# Create subnet for kubernetes cluster
resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.0.0/16"]
}

# Create subnet for virtual machines if necessary
# resource "azurerm_subnet" "vms" {
#   name                 = "vms"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.3.0.0/16"]
# }

# Create kubernetes cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                              = var.kubernetes_cluster_name
  location                          = var.resources_location
  resource_group_name               = azurerm_resource_group.rg.name
  kubernetes_version                = "1.23.5"
  dns_prefix                        = "yoda-k8s-cluster-aks-dns"
  oidc_issuer_enabled               = false
  role_based_access_control_enabled = true

  default_node_pool {
    name           = "agentpool"
    vm_size        = "Standard_DS2_v2"
    node_count     = 1
    vnet_subnet_id = azurerm_subnet.aks.id
    # zones = [
    #   "1",
    #   "2",
    #   "3",
    # ]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.gateway.id
  }

  # key_vault_secrets_provider {
  #   secret_rotation_enabled = false
  # }

  # oms_agent {
  #   log_analytics_workspace_id = azurerm_log_analytics_workspace.la.id
  # }

  tags = var.tags
}

# Create additional node pool in kubernetes cluster
resource "azurerm_kubernetes_cluster_node_pool" "aks" {
  name                  = "linux"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_DS2_v2"
  node_count            = 1
  vnet_subnet_id        = azurerm_subnet.aks.id
  tags                  = {}
}

# Create public ip
resource "azurerm_public_ip" "ip" {
  name                = var.public_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resources_location
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  zones               = []
  tags                = {}
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet.name}-rdrcfg"
}

# Create application gateway
resource "azurerm_application_gateway" "gateway" {
  name                = var.application_gateway_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resources_location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "yoda-cookie-ip-config"
    subnet_id = azurerm_subnet.gateway.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 10010
  }

  tags = var.tags

}

