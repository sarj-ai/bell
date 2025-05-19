output "asterisk_ip" {
  description = "The public IP address of the asterisk VM"
  value       = google_compute_address.asterisk_static_ip.address
}

output "kamailio_ip" {
  description = "The public IP address of the Kamailio VM"
  value       = google_compute_address.kamailio_static_ip.address
}

