resource "docker_volume" "jenkins_controller" {
  name = "jenkins-controller"
}

resource "docker_config" "casc_config" {
  name = "casc-config.yaml"
  data = base64encode(yamlencode(local.casc_config))
}

resource "docker_config" "agent_entrypoint" {
  name = "agent-entrypoint.sh"
  data = base64encode(file(("${path.module}/script/agent-entrypoint.sh")))
}

resource "docker_config" "export_agent_secret" {
  name = "export-agent-secret.groovy"
  data = base64encode(file(("${path.module}/init.groovy.d/export-agent-secret.groovy")))
}

resource "docker_service" "jenkins_controller" {
  name = "jenkins-controller"

  task_spec {
    container_spec {
      image = "ghcr.io/nodadyoushutup/jenkins-controller:0.0.1"

      env = {
        JAVA_OPTS                       = "-Djenkins.install.runSetupWizard=false"
        JENKINS_SECURITY_ADMIN_USERNAME = "admin"
        JENKINS_SECURITY_ADMIN_PASSWORD = "password"
        CASC_JENKINS_CONFIG             = "/jenkins/casc_configs"
      }

      mounts {
        target = "/var/jenkins_home"
        source = docker_volume.jenkins_controller.name
        type   = "volume"
      }
      mounts {
        target = "/dev/kvm"
        source = "/dev/kvm"
        type   = "bind"
      }

      mounts {
        target = "/var/jenkins_home/.jenkins"
        source = pathexpand("~/.jenkins")
        type   = "bind"
      }

      mounts {
        target = "/var/jenkins_home/.ssh"
        source = pathexpand("~/.ssh")
        type   = "bind"
      }

      mounts {
        target = "/var/jenkins_home/.kube"
        source = pathexpand("~/.kube")
        type   = "bind"
      }

      mounts {
        target = "/var/jenkins_home/.tfvars"
        source = pathexpand("~/.tfvars")
        type   = "bind"
      }

      configs {
        config_id   = docker_config.casc_config.id
        config_name = docker_config.casc_config.name
        file_name   = "/jenkins/casc_configs/config.yaml"
      }

      configs {
        config_id   = docker_config.export_agent_secret.id
        config_name = docker_config.export_agent_secret.name
        file_name   = "/usr/share/jenkins/ref/init.groovy.d/export-agent-secret.groovy"
      }

      dns_config {
        nameservers = ["1.1.1.1", "8.8.8.8"]
      }

      healthcheck {
        # /login is public and doesn’t require a crumb or auth
        test         = ["CMD", "curl", "-fsS", "http://127.0.0.1:8080/whoAmI/api/json?tree=authenticated"]
        interval     = "10s"
        timeout      = "5s"
        retries      = 30
        start_period = "1m"
      }
    }
    placement {
      platforms {
        os           = "linux"
        architecture = "arm64"
      }
    }
  }

  endpoint_spec {
    ports {
      target_port    = 8080
      published_port = 8080
      publish_mode   = "ingress"
    }
    ports {
      target_port    = 50000
      published_port = 50000
      publish_mode   = "ingress"
    }
  }
}

resource "null_resource" "wait_for_service" {
  depends_on = [docker_service.jenkins_controller]
  triggers = {
    endpoint     = "http://192.168.1.44:8080/whoAmI/api/json?tree=authenticated"
    delay        = "5"
    max_attempts = "60"
    script_sha1  = filesha1("${path.module}/script/healthcheck.sh")
    script2_sha1 = filesha1("${path.module}/script/agent-entrypoint.sh")
  }

  provisioner "local-exec" {
    command = "MAX_ATTEMPTS=60 TIMEOUT=5 bash ${path.module}/script/healthcheck.sh http://192.168.1.44:8080/whoAmI/api/json?tree=authenticated 5"
  }
}

module "jenkins_agent" {
  depends_on = [null_resource.wait_for_service]
  for_each   = { for node in local.casc_config.jenkins.nodes : node.permanent.name => node }
  source     = "./modules/jenkins-agent"

  name        = each.value.permanent.name
  jenkins_url = "http://192.168.1.44:8080"

  agent_entrypoint_config_id   = docker_config.agent_entrypoint.id
  agent_entrypoint_config_name = docker_config.agent_entrypoint.name
}
