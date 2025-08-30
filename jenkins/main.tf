resource "null_resource" "wait_for_service" {
  triggers = {
    endpoint     = "http://192.168.1.110:8080/whoAmI/api/json?tree=authenticated"
    delay        = "5"
    max_attempts = "60"
    script_sha1  = filesha1("${path.module}/script/healthcheck.sh")
  }

  provisioner "local-exec" {
    command = "MAX_ATTEMPTS=60 TIMEOUT=5 bash ${path.module}/script/healthcheck.sh http://192.168.1.110:8080/whoAmI/api/json?tree=authenticated 5"
  }
}

resource "jenkins_job" "terraform_jenkins" {
  depends_on = [null_resource.wait_for_service]
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
  depends_on = [null_resource.wait_for_service]
  name       = "terraform-proxmox"
  template = templatefile("${path.module}/job.xml", {
    description        = "Proxmox assets"
    project_url        = "https://github.com/nodadyoushutup/terraform-proxmox"
    scm_repository_url = "https://github.com/nodadyoushutup/terraform-proxmox"
    script_path        = "pipeline.jenkins"
    auto_approve       = local.job_parameters.terraform_proxmox.auto_approve
  })
}
