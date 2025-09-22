terraform {
  backend "s3" {}

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

provider "docker" {
  host     = var.provider_config.host
  ssh_opts = var.provider_config.ssh_opts
}
