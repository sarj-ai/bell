terraform {
  required_providers {

    google = {
      source = "hashicorp/google"
    }
  }

  backend "gcs" {
    bucket      = "sarj-bulbul-terraform-storage"
    prefix      = "terraform/state"
    credentials = "./tf-service-credentials.json"
  }
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "run.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbuild.googleapis.com",
    "servicenetworking.googleapis.com",
    "domains.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudscheduler.googleapis.com",
    "datastream.googleapis.com"
  ]
}

resource "null_resource" "ensure_services_enabled" {
  for_each = toset(var.gcp_service_list)

  triggers = {
    always_run = "once"
  }

  provisioner "local-exec" {
    command = "gcloud services enable ${each.key} --project ${var.project}"
  }


  lifecycle {
    prevent_destroy = false
  }
}

module "sql" {
  source            = "./sql"
  project           = var.project
  region            = var.region
  database_user     = var.database_user
  database_password = var.database_password
}

module "services" {
  source  = "./services"
  region  = var.region
  project = var.project
}
