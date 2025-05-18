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

resource "google_compute_instance" "freeswitch" {
  name         = "freeswitch"
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
      nat_ip = google_compute_address.freeswitch_static_ip.address
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

    # Install FreeSWITCH
    wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add -
    echo "deb http://files.freeswitch.org/repo/deb/debian-release/ bookworm main" > /etc/apt/sources.list.d/freeswitch.list
    apt-get update
    apt-get install -y freeswitch freeswitch-meta-all

    # Configure FreeSWITCH to use Cloud Storage
    cat > /etc/freeswitch/autoload_configs/cloud_storage.conf.xml <<'FSEOF'
    <configuration name="cloud_storage.conf" description="Cloud Storage Configuration">
      <settings>
        <param name="bucket-name" value="${var.bucket_name}"/>
        <param name="recordings-path" value="recordings"/>
        <param name="voicemail-path" value="voicemail"/>
      </settings>
    </configuration>
    FSEOF

    # Set up Cloud SQL environment for FreeSWITCH
    cat > /etc/systemd/system/freeswitch.service.d/override.conf <<'SERVICEEOF'
    [Service]
    Environment="PG_SOCKET_URI=${var.pg_socket_uri}"
    Environment="DB_NAME=${var.project}"
    SERVICEEOF

    systemctl daemon-reload
    systemctl restart freeswitch
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["voip", "freeswitch"]
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

    # Install Kamailio
    wget -O- https://deb.kamailio.org/kamailiodebkey.gpg | apt-key add -
    echo "deb http://deb.kamailio.org/kamailio56 bookworm main" > /etc/apt/sources.list.d/kamailio.list
    apt-get update
    apt-get install -y kamailio kamailio-postgres-modules kamailio-tls-modules kamailio-websocket-modules

    # Configure Kamailio environment variables for database connection
    mkdir -p /etc/systemd/system/kamailio.service.d/
    cat > /etc/systemd/system/kamailio.service.d/override.conf <<'SERVICEEOF'
    [Service]
    Environment="PG_SOCKET_URI=${var.pg_socket_uri}"
    Environment="DB_NAME=${var.project}"
    SERVICEEOF

    # Update kamailio.cfg to use environment variables for DB connection
    sed -i 's/#!define WITH_MYSQL/#!define WITH_POSTGRES/' /etc/kamailio/kamailio.cfg
    sed -i 's/#!substdef "!DBURL!mysql:\/\/kamailio:kamailiorw@localhost\/kamailio!g"/#!substdef "!DBURL!postgres:\/\/$DB_USER@$PG_SOCKET_URI\/$DB_NAME!g"/' /etc/kamailio/kamailio.cfg

    systemctl daemon-reload
    systemctl restart kamailio
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

  source_tags = ["voip", "freeswitch", "kamailio"]
  target_tags = ["voip", "freeswitch", "kamailio"]
}

