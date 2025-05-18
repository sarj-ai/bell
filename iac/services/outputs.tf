output "freeswitch_ip" {
  description = "The public IP address of the FreeSWITCH VM"
  value       = google_compute_address.freeswitch_static_ip.address
}

output "kamailio_ip" {
  description = "The public IP address of the Kamailio VM"
  value       = google_compute_address.kamailio_static_ip.address
}

