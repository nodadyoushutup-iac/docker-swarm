resource "jenkins_job" "terraform_jenkins" {
  name       = "terraform-jenkins"
  template = templatefile("${path.module}/job.xml", {
    description        = "Jenkins assets"
    project_url        = "https://github.com/nodadyoushutup/terraform-jenkins"
    scm_repository_url = "https://github.com/nodadyoushutup/terraform-jenkins"
    script_path        = "jenkins/pipeline.jenkins"
    auto_approve       = local.job_parameters.terraform_jenkins.auto_approve
  })
}

resource "jenkins_job" "terraform_proxmox" {
  name       = "terraform-proxmox"
  template = templatefile("${path.module}/job.xml", {
    description        = "Proxmox assets"
    project_url        = "https://github.com/nodadyoushutup/terraform-proxmox"
    scm_repository_url = "https://github.com/nodadyoushutup/terraform-proxmox"
    script_path        = "pipeline.jenkins"
    auto_approve       = local.job_parameters.terraform_proxmox.auto_approve
  })
}
