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

resource "google_compute_address" "freeswitch_static_ip" {
  name    = "freeswitch-static-ip"
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

# TOD Freeswitch and Kamailio VMs 

