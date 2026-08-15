output "dashboard_url" {
  value       = "http://sre.local:${var.http_port}"
  description = "Access URL for the SRE Dashboard"
}

output "traefik_dashboard_url" {
  value       = "http://localhost:${var.traefik_dashboard_port}"
  description = "Access URL for Traefik Admin Panel"
}

output "container_id" {
  value       = docker_container.sre_dashboard.id
  description = "Docker container ID for SRE Dashboard"
}
