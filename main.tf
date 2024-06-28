# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  backend "gcs" {
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.79.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "google" {
  project = "sawblade"
  region  = "europe-west1"
}

resource "google_compute_instance" "webserver" {
  name         = "web-server-instance"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  tags = ["webserver"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = "sudo apt-get update && sudo apt-get install -y nginx && echo 'Hello, World!' > /var/www/html/index.nginx-debian.html"
}

resource "google_compute_firewall" "allow-http-to-webserver" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["webserver"]

  source_ranges = ["0.0.0.0/0"]
}

output "web-address" {
  value = "http://${google_compute_instance.webserver.network_interface.0.access_config.0.nat_ip}"
}
