terraform {
  required_providers {
    jenkins = {
      source  = "taiidani/jenkins"
      version = "0.11.0"
    }
  }
}

provider "jenkins" {
  server_url = var.provider_config.server_url
  username   = var.provider_config.username
  password   = var.provider_config.password
}
