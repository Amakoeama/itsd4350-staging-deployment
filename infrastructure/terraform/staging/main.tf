
#--- Terraform and provider configuration ---
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

#--- Staging network ---
resource "docker_network" "staging" {
  name = "${var.project_name}-${var.environment}-network"
}

#--- Flask application container ---
resource "docker_container" "staging_app" {
  name  = "${var.project_name}-${var.environment}-app"
  image = var.docker_image

  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.staging.name
  }

  ports {
    internal = var.container_port
    external = var.host_port
    ip       = "127.0.0.1"
  }

  env = [
    "APP_ENV=${var.environment}"
  ]
}
