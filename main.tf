#create network
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
  auto_create_subnetworks = false
  
  depends_on = [google_project_service.api]
}

#create subnetwork
resource "google_compute_subnetwork" "subnet" {
  name          = "gallery-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

#create virtual machine
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-standard-2"
  zone    = var.zone

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
    }
  }

  metadata_startup_script = file("${path.module}/cloud-init.sh")

  metadata = {
    enable-oslogin = "TRUE"
  }
  
   service_account {
    email  = google_service_account.sa-name.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["gallery-vm"]
}

#service account for vm
resource "google_service_account" "sa-name" {
  account_id = "sa-name"
  display_name = "SA"
}

#permissions of vm service account
resource "google_project_iam_member" "firestore_owner_binding" {
  project = var.project
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.sa-name.email}"
}
resource "google_project_iam_member" "vm_sql_client" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.sa-name.email}"
}
resource "google_project_iam_member" "vm_can_upload" {
  project = var.project
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.sa-name.email}"
}

resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.my_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}


#creating bucket
resource "google_storage_bucket" "my_bucket" {
  name          = "final-proj-photos"
  location      = "US"
  storage_class = "STANDARD"
  force_destroy = true
  uniform_bucket_level_access = true
}


#Reserving IP range for SQL private connection on subnetwork
resource "google_compute_global_address" "private_ip_range" {
  name          = "google-managed-services-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

#creating the VPC peering connection for SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}



#create the MySql instance
resource "google_sql_database_instance" "mysql_instance" {
  name             = "sql-instance"
  database_version = "MYSQL_8_0"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-n1-standard-1"

    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.project}/global/networks/${google_compute_network.vpc_network.name}"
    }
  }
  deletion_protection = false
}

# Create a MySQL user
resource "google_sql_user" "default_user" {
  name     = "root"
  instance = google_sql_database_instance.mysql_instance.name
}

# Create a database inside the instance
resource "google_sql_database" "default_db" {
  name     = "gallerydb"  
  instance = google_sql_database_instance.mysql_instance.name 
}

#firewall rules
resource "google_compute_firewall" "allow_mysql" {
  name    = "allow-mysql-to-sql"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = ["10.0.0.0/16"] 
  target_tags   = ["gallery-vm"]  
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gallery-vm"]
}
