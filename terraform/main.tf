terraform {
  required_version = ">= 1.5.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

# Network
resource "docker_network" "sre_network" {
  name = "sre_ops_network"
}

# Image
resource "docker_image" "sre_dashboard" {
  name         = "ghcr.io/gethomepage/homepage:latest"
  keep_locally = true
}

# Traefik Container
resource "docker_container" "traefik" {
  name    = "traefik"
  image   = "traefik:v2.10"
  restart = "unless-stopped"

  command = [
    "--api.insecure=true",
    "--providers.docker=true",
    "--providers.docker.exposedbydefault=false",
    "--entrypoints.web.address=:80"
  ]

  ports {
    internal = 80
    external = var.http_port
  }

  ports {
    internal = 8080
    external = var.traefik_dashboard_port
  }

  networks_advanced {
    name = docker_network.sre_network.name
  }

  mounts {
    target   = "/var/run/docker.sock"
    source   = "/var/run/docker.sock"
    type     = "bind"
    read_only = true
  }
}

# Authelia Container
resource "docker_container" "authelia" {
  name    = "authelia"
  image   = "authelia/authelia:latest"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.sre_network.name
  }

  mounts {
    target = "/config"
    source = "${abspath(path.module)}/../config/authelia"
    type   = "bind"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.authelia.rule"
    value = "Host(`auth.sre.local`)"
  }
  labels {
    label = "traefik.http.routers.authelia.entrypoints"
    value = "web"
  }
  labels {
    label = "traefik.http.services.authelia.loadbalancer.server.port"
    value = "9091"
  }
  labels {
    label = "traefik.http.middlewares.authelia.forwardauth.address"
    value = "http://authelia:9091/api/verify?type=plain"
  }
  labels {
    label = "traefik.http.middlewares.authelia.forwardauth.trustForwardHeader"
    value = "true"
  }
}

# SRE Dashboard Container
resource "docker_container" "sre_dashboard" {
  name    = "sre_dashboard_tf"
  image   = docker_image.sre_dashboard.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.sre_network.name
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.sre-dashboard.rule"
    value = "Host(`sre.local`)"
  }
  labels {
    label = "traefik.http.routers.sre-dashboard.middlewares"
    value = "authelia@docker"
  }
  labels {
    label = "traefik.http.services.sre-dashboard.loadbalancer.server.port"
    value = "3000"
  }

  mounts {
    target = "/app/config"
    source = "${abspath(path.module)}/../config"
    type   = "bind"
  }
}
