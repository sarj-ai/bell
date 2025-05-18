output "bucket_name" {
  value = google_storage_bucket.project_bucket.name
}

output "local_bucket_name" {
  value = google_storage_bucket.local_project_bucket.name
}
