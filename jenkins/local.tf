locals {
  job_parameters = {
    terraform_jenkins = {
      auto_approve = true
    }
    terraform_proxmox = {
      auto_approve = true
    }
  }
}
