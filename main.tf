module "jenkins_controller" {
  # source = "./modules/jenkins-controller/infra"
  source = "github.com/nodadyoushutup/jenkins-controller//infra?ref=main"

  casc_config          = local.casc_config
  healthcheck_endpoint = format("%s/whoAmI/api/json?tree=authenticated", local.controller_url)
}

module "jenkins_agent" {
  depends_on = [module.jenkins_controller]
  for_each   = { for node in local.casc_config.jenkins.nodes : node.permanent.name => node }
  source     = "./modules/jenkins-agent"

  name        = each.value.permanent.name
  jenkins_url = local.controller_url
}
