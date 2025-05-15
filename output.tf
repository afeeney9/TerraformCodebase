# Output the public IP of the VM
output "vm_public_ip" {
  description = "The public IP address of the VM"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

# Output the private IP of the VM
output "vm_private_ip" {
  description = "The private IP address of the VM"
  value       = google_compute_instance.vm_instance.network_interface[0].network_ip
}

# Output the database connection name for MySQL
output "db_connection_name" {
  description = "The connection name for the MySQL database instance"
  value       = google_sql_database_instance.mysql_instance.connection_name
}

# Output the private IP of the MySQL database instance
output "db_private_ip" {
  description = "The private IP address of the MySQL database"
  value       = google_sql_database_instance.mysql_instance.private_ip_address
}
