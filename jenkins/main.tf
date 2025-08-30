resource "jenkins_job" "terraform_jenkins" {
  name = "terraform-jenkins"
  template = templatefile("${path.module}/template/terraform_docker_app.xml", {
    description        = "Jenkins assets"
    project_url        = "https://github.com/nodadyoushutup/terraform-jenkins"
    scm_repository_url = "https://github.com/nodadyoushutup/terraform-jenkins"
    script_path        = "pipeline/pipeline.jenkins"
    auto_approve       = local.job_parameters.terraform_jenkins.auto_approve
    docker_tfvars      = local.job_parameters.terraform_jenkins.docker_tfvars
    app_tfvars         = local.job_parameters.terraform_jenkins.app_tfvars
  })
}

# LEAVE COMMENTED
# resource "jenkins_job" "terraform_proxmox" {
#   name = "terraform-proxmox"
#   template = templatefile("${path.module}/template/terraform_app.xml", {
#     description        = "Proxmox assets"
#     project_url        = "https://github.com/nodadyoushutup/terraform-proxmox"
#     scm_repository_url = "https://github.com/nodadyoushutup/terraform-proxmox"
#     script_path        = "pipeline/pipeline.jenkins"
#     auto_approve       = local.job_parameters.terraform_proxmox.auto_approve
#     app_tfvars         = local.job_parameters.terraform_jenkins.app_tfvars
#   })
# }
