terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "google_sql_database_instance" "instance" {
  project             = var.project
  name                = var.project
  database_version    = "POSTGRES_17"
  region              = var.region
  deletion_protection = true

  settings {
    tier    = "db-custom-1-3840"
    edition = "ENTERPRISE"

    ip_configuration {
      ssl_mode     = "ENCRYPTED_ONLY"
      ipv4_enabled = true
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 4500
      record_client_address   = true
      record_application_tags = true
    }

    backup_configuration {
      enabled                        = true
      location                       = var.region
      point_in_time_recovery_enabled = true
    }

    database_flags {
      name  = "cloudsql.logical_decoding"
      value = "on"
    }

    database_flags {
      name  = "cloudsql.enable_index_advisor"
      value = "on"
    }

    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }

  }
}


resource "google_sql_database" "db" {
  project  = var.project
  name     = var.project
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "pgwriter" {
  project  = var.project
  instance = google_sql_database_instance.instance.name
  name     = var.database_user
  password = var.database_password

  deletion_policy = "ABANDON"
}
