locals {
  job_parameters = {
    terraform_jenkins = {
      auto_approve  = true
      docker_tfvars = "~/.tfvars/docker/jenkins.tfvars"
      app_tfvars = "~/.tfvars/jenkins.tfvars"
      app_subdir = "jenkins"
    }
    terraform_proxmox = {
      auto_approve = true
      app_tfvars = "~/.tfvars/jenkins.tfvars"
    }
  }
}
