#You may get an error that connection cannot be created in a subnet since it has private endpoint network policies enabled. To disable run below.
#az network vnet subnet update --name [subnet name] --resource-group [vnet/subnet rg] --vnet-name [vnet-name] --disable-private-endpoint-network-policies true

data "azurerm_resource_group" "postgresql_rg" {
  name     = var.rg
}

data "azurerm_subnet" "endpoint_subnet" {
  name                    = var.subnet_name
  virtual_network_name    = var.vnet_name
  resource_group_name     = var.vnet_rg_name
}

resource "random_string" "postgresql_password" {
  length  = 16
  special = true
}

resource "azurerm_postgresql_server" "postgresql" {
  name                = var.server_name
  resource_group_name = data.azurerm_resource_group.postgresql_rg.name
  location            = var.region

  sku_name = var.database_sku
  
  tags = {
    BillingIndicator      = var.bill_indicator_tag
    CompanyCode           = var.company_code_tag  
    EnvironmentType       = var.env_tag           
    ConsumerOrganization1 = var.consumer_org1_tag 
    ConsumerOrganization2 = var.consumer_org2_tag
    SupportStatus         = var.support_stat_tag  
  }

  storage_profile {
    storage_mb            = var.database_storage
    backup_retention_days = var.backup_days
    geo_redundant_backup  = var.geo_redundant
    auto_grow             = var.auto_grow
  }

  administrator_login          = var.database_username
  administrator_login_password = random_string.postgresql_password.result
  version                      = var.database_version
  ssl_enforcement              = var.db_ssl_enforcement
}

resource "azurerm_postgresql_database" "database" {
  name                = var.database_name
  resource_group_name = data.azurerm_resource_group.postgresql_rg.name
  server_name         = azurerm_postgresql_server.postgresql.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_private_endpoint" "database" {
  name                = var.priv_endpoint_name
  location            = var.region
  resource_group_name = data.azurerm_resource_group.postgresql_rg.name
  subnet_id           = data.azurerm_subnet.endpoint_subnet.id

  private_service_connection {
    name                           = var.priv_endpoint_name
    private_connection_resource_id = azurerm_postgresql_server.postgresql.id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }
}

data "azurerm_private_endpoint_connection" "dbconnection" {
  name                = azurerm_private_endpoint.database.name
  resource_group_name = var.rg
}


#  Example to allow all Azure network access to database. 
#  resource "azurerm_postgresql_firewall_rule" "terraform" {
#   name                = "${var.server_name}-firewallrule"
#   resource_group_name = var.rg
#   server_name         = azurerm_postgresql_server.postgresql.name
#   start_ip_address    = "0.0.0.0"
#   end_ip_address      = "0.0.0.0"
# }

# Example rule to allow subnet access to database.
# resource "azurerm_postgresql_virtual_network_rule" "example" {
#   name                                 = var.vnet-rule
#   resource_group_name                  = azurerm_resource_group.example.name
#   server_name                          = azurerm_postgresql_server.example.name
#   subnet_id                            = azurerm_subnet.internal.id
#   ignore_missing_vnet_service_endpoint = true
# }

