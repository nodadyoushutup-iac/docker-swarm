module "jenkins_controller" {
  source = "./modules/jenkins-controller"

  casc_config          = local.casc_config
  healthcheck_endpoint = "http://192.168.1.44:8080/whoAmI/api/json?tree=authenticated"
}

module "jenkins_agent" {
  depends_on = [module.jenkins_controller]
  for_each   = { for node in local.casc_config.jenkins.nodes : node.permanent.name => node }
  source     = "./modules/jenkins-agent"

  name        = each.value.permanent.name
  jenkins_url = "http://192.168.1.44:8080"
}
