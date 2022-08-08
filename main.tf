###########################################################################
### RESOURCE GROUP
###########################################################################
resource "azurerm_resource_group" "rg" {
    name     = "${var.resource_group_prefix}-AKS"
    location = var.az_location
}

data "azurerm_client_config" "current" {}


###########################################################################
#   NETWORK
###########################################################################
resource "azurerm_network_security_group" "vnet-spoke-nsg" {
    name                = "NSG-SPOKE"
    location            = var.az_location
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "AllowHTTP-HTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80", "443"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

}

resource "azurerm_network_security_group" "vnet-spoke-nsg-network" {
    name                = "NSG-SPOKE-NETWORK"
    location            = var.az_location
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "AllowHTTP-HTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80", "443"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowHighPorts"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["65200-65535"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    }


resource "azurerm_virtual_network" "vnet-spoke" {
    name                = "VNET-SPOKE"
    location            = var.az_location
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = ["192.1.0.0/16"]
    
    subnet {
        name           = "SUBNET-NETWORK"
        address_prefix = "192.1.1.0/24"
        security_group = azurerm_network_security_group.vnet-spoke-nsg-network.id
    }
    
    subnet {
        name           = "SUBNET-AKS"
        address_prefix = "192.1.2.0/24"
        security_group = azurerm_network_security_group.vnet-spoke-nsg.id
    }

    tags = local.common_tags

}

resource "azurerm_public_ip" "appgwy_publicip" {
  name                = "appgwy_publicip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.az_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

###########################################################################
#   Application Gateway
###########################################################################

resource "azurerm_application_gateway" "appgwy" {
    name                = local.appgwyname
    resource_group_name = azurerm_resource_group.rg.name
    location            = var.az_location

    sku {
        name     = "WAF_v2"
        tier     = "WAF_v2"
    }

    autoscale_configuration {
        min_capacity = 1
        max_capacity = 3
    }

    gateway_ip_configuration {
        name      = "my-gateway-ip-configuration"
        subnet_id = "${azurerm_virtual_network.vnet-spoke.subnet.*.id[0]}"
    }

    frontend_port {
        name = "${local.appgwyname}-feport"
        port = 80
    }

    frontend_ip_configuration {
        name                 = "${local.appgwyname}-feip"
        public_ip_address_id = azurerm_public_ip.appgwy_publicip.id
    }

    backend_address_pool {
        name = "${local.appgwyname}-beap"
        #ip_addresses = azurerm_kubernetes_cluster.AKS.default_node_pool
    }

    backend_http_settings {
        name                  = "${local.appgwyname}-be-htst"
        cookie_based_affinity = "Disabled"
        path                  = "/"
        port                  = 80
        protocol              = "Http"
        request_timeout       = 60
    }

    http_listener {
        name                           = "${local.appgwyname}-httplstn"
        frontend_ip_configuration_name = "${local.appgwyname}-feip"
        frontend_port_name             = "${local.appgwyname}-feport"
        protocol                       = "Http"
    }

    request_routing_rule {
        name                       = "${local.appgwyname}-rqrt"
        rule_type                  = "Basic"
        http_listener_name         = "${local.appgwyname}-httplstn"
        backend_address_pool_name  = "${local.appgwyname}-beap"
        backend_http_settings_name = "${local.appgwyname}-be-htst"
    }
}

###########################################################################
### Key Vault
###########################################################################


resource "azurerm_key_vault" "kvt_aks" {
  name                            = "kvtaks"
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  location                        = var.az_location
  resource_group_name             = azurerm_resource_group.rg.name
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enable_rbac_authorization       = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = 7
  
  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

###########################################################################
### AKS
###########################################################################

resource "azurerm_kubernetes_cluster" "AKS" {
    name                = "aks-abnamro-challenge"
    location            = var.az_location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix          = "abnamrochallenge"
    #key_vault_secrets_provider {
    #}

    default_node_pool {
        name                = "npooldefault"
        enable_auto_scaling = true
        node_count          = 1
        max_count           = 3
        vm_size             = "Standard_DS2_v2"
        min_count           = 1
        vnet_subnet_id      = "${azurerm_virtual_network.vnet-spoke.subnet.*.id[1]}"
    }

    identity {
        type = "SystemAssigned"
    }

    ingress_application_gateway {
        gateway_id   = azurerm_application_gateway.appgwy.id
    }


    tags = local.common_tags

    depends_on = [
      azurerm_resource_group.rg,
      azurerm_virtual_network.vnet-spoke,
      azurerm_application_gateway.appgwy
    ]
  
}



