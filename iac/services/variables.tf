variable "slug" {
  type    = string
  default = "prod"
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
}

variable "project" {
  description = "The GCP project ID"
  type        = string
}


variable "pg_uri" {}
variable "pg_socket_uri" {}
