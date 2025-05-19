resource "google_compute_network" "voip_network" {
  project                 = var.project
  name                    = "voip-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "voip_subnet" {
  name          = "voip-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  project       = var.project
  network       = google_compute_network.voip_network.id
}

resource "google_compute_address" "asterisk_static_ip" {
  name    = "asterisk-static-ip"
  project = var.project
  region  = var.region
}

resource "google_compute_address" "kamailio_static_ip" {
  name    = "kamailio-static-ip"
  project = var.project
  region  = var.region
}

resource "google_compute_firewall" "sip_firewall" {
  name    = "allow-sip"
  network = google_compute_network.voip_network.name
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["5060", "5061"]
  }

  allow {
    protocol = "udp"
    ports    = ["5060", "5061"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "rtp_firewall" {
  name    = "allow-rtp"
  network = google_compute_network.voip_network.name
  project = var.project

  allow {
    protocol = "udp"
    ports    = ["16384-32768"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "ssh_firewall" {
  name    = "allow-ssh"
  network = google_compute_network.voip_network.name
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "web_firewall" {
  name    = "allow-web"
  network = google_compute_network.voip_network.name
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8089"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "asterisk" {
  name         = "asterisk"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  project      = var.project

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.voip_network.id
    subnetwork = google_compute_subnetwork.voip_subnet.id
    access_config {
      nat_ip = google_compute_address.asterisk_static_ip.address
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y wget gnupg2 curl

    # Install Cloud SQL proxy
    curl -o /usr/local/bin/cloud_sql_proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.6.1/cloud-sql-proxy.linux.amd64
    chmod +x /usr/local/bin/cloud_sql_proxy

    # Install Google Cloud SDK
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update
    apt-get install -y google-cloud-cli
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["voip", "asterisk"]
}

# Kamailio VM
resource "google_compute_instance" "kamailio" {
  name         = "kamailio"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  project      = var.project

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.voip_network.id
    subnetwork = google_compute_subnetwork.voip_subnet.id
    access_config {
      nat_ip = google_compute_address.kamailio_static_ip.address
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y gnupg2 wget curl

    # Install Cloud SQL proxy
    curl -o /usr/local/bin/cloud_sql_proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.6.1/cloud-sql-proxy.linux.amd64
    chmod +x /usr/local/bin/cloud_sql_proxy

    # Install Google Cloud SDK
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update
    apt-get install -y google-cloud-cli
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["voip", "kamailio"]
}

resource "google_compute_firewall" "internal_voip_firewall" {
  name    = "allow-internal-voip"
  network = google_compute_network.voip_network.name
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["8021"]
  }

  allow {
    protocol = "udp"
    ports    = ["4060"]
  }

  source_tags = ["voip", "asterisk", "kamailio"]
  target_tags = ["voip", "asterisk", "kamailio"]
}

