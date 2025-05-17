output "connection_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.connection_name
}

output "pg_socket_uri" {
  value = "socket://${urlencode(var.database_user)}:${urlencode(var.database_password)}@${urlencode("/cloudsql/${google_sql_database_instance.instance.connection_name}")}/${var.project}"
}

output "pg_ip_uri" {
  value = "postgres://${var.database_user}:${var.database_password}@${google_sql_database_instance.instance.ip_address.0.ip_address}/${google_sql_database.db.name}"
}


output "pg_uri" {
  value = "postgres://${urlencode(var.database_user)}:${urlencode(var.database_password)}@/${urlencode(google_sql_database.db.name)}?host=${urlencode("/cloudsql/${google_sql_database_instance.instance.connection_name}")}"

}
