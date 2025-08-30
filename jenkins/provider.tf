terraform {
  required_providers {
    jenkins = {
      source  = "taiidani/jenkins"
      version = "0.11.0"
    }
  }
}

provider "jenkins" {
  server_url = "http://192.168.1.110:8080/"
  username   = "admin"
  password   = "password"
}
