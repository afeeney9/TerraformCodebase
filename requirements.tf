terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
  backend "gcs" {
    bucket = "my-terraform-gcs"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "api" {
  for_each = toset(local.apis)
  service = each.key
  disable_on_destroy = false
}




