variable "docker_host" {
  type        = string
  default     = "unix:///var/run/docker.sock"
  description = "Docker daemon socket path or remote TCP host"
}

variable "http_port" {
  type        = number
  default     = 8000
  description = "Custom external HTTP port for Traefik access"
}

variable "traefik_dashboard_port" {
  type        = number
  default     = 8088
  description = "Custom external port for Traefik dashboard"
}

variable "timezone" {
  type        = string
  default     = "UTC"
  description = "Timezone for system logs and widgets"
}
