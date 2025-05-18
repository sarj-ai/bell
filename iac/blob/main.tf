resource "google_storage_bucket" "project_bucket" {
  name          = "sarj-bell-storage"
  location      = var.region
  force_destroy = true
  project       = var.project

  uniform_bucket_level_access = true

  cors {
    origin = [
      "https://*",
      "http://localhost:*",
    ]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket" "local_project_bucket" {
  name          = "local-sarj-bell-storage"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = false

  project = var.project

  cors {
    origin = [
      "https://*",
      "http://localhost:*",
    ]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}
