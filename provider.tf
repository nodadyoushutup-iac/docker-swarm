terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
    jenkins = {
      source = "taiidani/jenkins"
      version = "0.11.0"
    }
    
  }
}

provider "docker" {
  host     = "ssh://nodadyoushutup@192.168.1.110:22"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-i", "~/.ssh/id_rsa"
  ]
}

provider "jenkins" {
  server_url = "http://192.168.1.110:8080/"
  username   = "admin"
  password   = "password"
}