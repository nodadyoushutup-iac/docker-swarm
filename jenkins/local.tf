locals {
  job_parameters = {
    terraform_jenkins = {
      auto_approve   = true
      docker_tfvars  = "~/.tfvars/docker/jenkins.tfvars"
      app_tfvars = "~/.tfvars/jenkins.tfvars"
    }
    terraform_proxmox = {
      auto_approve = true
    }
  }
}
