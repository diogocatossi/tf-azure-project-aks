
### RESOURCE GROUP

resource "azurerm_resource_group" "rg" {
    name     = "${var.resource_group_prefix}-AKS"
    location = var.az_location
}

### NSG
resource "azurerm_network_security_group" "vnet-hub-nsg" {
    name                = "NSG-HUB"
    location            = var.az_location
    resource_group_name = azurerm_resource_group.rg.name
}

### VNET
resource "azurerm_virtual_network" "vnet-hub" {
    name                = "VNET-HUB"
    location            = var.az_location
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = ["10.0.0.0/16"]
    
    subnet {
        name           = "SUBNET-NETWORK"
        address_prefix = "10.0.1.0/24"
        security_group = azurerm_network_security_group.vnet-hub-nsg.name
    }
    
    subnet {
        name           = "SUBNET-AKS"
        address_prefix = "10.0.2.0/24"
        security_group = azurerm_network_security_group.vnet-hub-nsg.name
    }

    tags = local.common_tags

}


### AKS
resource "azurerm_kubernetes_cluster" "AKS" {
    name                = "aks-abnamro-challenge"
    location            = var.az_location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix          = "abnamrochallenge"

    default_node_pool {
        name = "npooldefault"
        node_count = 1
        vm_size = "StandStandard_DS2_v2"   
    }

    identity {
        type = "SystemAssigned"
    }

    tags = local.common_tags
  
}