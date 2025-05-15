variable "project" {
    default = "finalproj-459717"
 }

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

locals {
  apis = ["compute.googleapis.com", "container.googleapis.com", "logging.googleapis.com", "secretmanager.googleapis.com" ]
}
