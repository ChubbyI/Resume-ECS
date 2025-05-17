# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "local" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# Create VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "resume-vpc-network"
  auto_create_subnetworks = false
}

# Create subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "resume-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Cloud SQL instance
resource "google_sql_database_instance" "resume_db" {
  name             = "resume-db-instance"
  database_version = "MYSQL_8_0"
  region          = var.region
  depends_on      = [google_project_service.services]

  settings {
    tier = "db-f1-micro"
    
    backup_configuration {
      enabled = true
      binary_log_enabled = true
    }

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"  # Note: For production, restrict this to specific IPs
      }
    }
  }

  deletion_protection = false  # Set to true for production
}

# Create database
resource "google_sql_database" "resume_database" {
  name     = "resume_db"
  instance = google_sql_database_instance.resume_db.name
}

# Create database user
resource "google_sql_user" "resume_user" {
  name     = var.db_user
  instance = google_sql_database_instance.resume_db.name
  password = var.db_password
}

# Create Cloud Storage bucket for static assets
resource "google_storage_bucket" "static_assets" {
  name          = "${var.project_id}-static-assets"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Make bucket public
resource "google_storage_bucket_iam_member" "public_rule" {
  bucket = google_storage_bucket.static_assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Cloud Run service
resource "google_cloud_run_service" "resume_app" {
  name     = "resume-app"
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image
        
        env {
          name  = "DB_HOST"
          value = google_sql_database_instance.resume_db.connection_name
        }
        
        env {
          name  = "DB_USER"
          value = var.db_user
        }
        
        env {
          name  = "DB_NAME"
          value = google_sql_database.resume_database.name
        }
        
        # DB password from Secret Manager
        env {
          name = "DB_PASS"
          value_from {
            secret_key_ref {
              name = "db-password"
              key  = "latest"
            }
          }
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.resume_db.connection_name
        "autoscaling.knative.dev/maxScale"      = "5"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.services]
}

# Make the Cloud Run service public
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.resume_app.name
  location = google_cloud_run_service.resume_app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}