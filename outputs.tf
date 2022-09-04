output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

# output "container_registry_id" {
#   value = azurerm_container_registry.acr.id
# }

output "public_ip_address" {
  value = azurerm_public_ip.ip.ip_address
}

output "virtual_network_address" {
  value = azurerm_virtual_network.vnet.address_space
}

output "gateway_subnet_address" {
  value = azurerm_subnet.gateway.address_prefixes
}

output "aks_subnet_address" {
  value = azurerm_subnet.aks.address_prefixes
}

# output "vms_subnet_address" {
#   value = azurerm_subnet.vms.address_prefixes
# }

