output "db_admin_password" {
  description = "Postgres db password"
  value       = random_string.postgresql_password.result
}

output "private_link_endpoint_ip" {
  value = "${data.azurerm_private_endpoint_connection.dbconnection.private_service_connection.0.private_ip_address}"
}