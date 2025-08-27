resource "docker_volume" "jenkins_controller" {
    name = "jenkins-controller"
}

resource "docker_volume" "jenkins_agent" {
    name = "jenkins-agent"
}

resource "docker_config" "casc_appearance" {
    name = "casc-appearance.yaml"
    data = base64encode(yamlencode(local.appearance))
}

# resource "docker_config" "casc_jenkins" {
#     name = "casc-jenkins.yaml"
#     data = yamlencode(local.jenkins)
# }

# resource "docker_config" "casc_credential" {
#     name = "casc-credential.yaml"
#     data = yamlencode(local.credentials)
# }

# resource "docker_config" "casc_unclassified" {
#     name = "casc-unclassified.yaml"
#     data = yamlencode(local.unclassified)
# }

# resource "docker_config" "export_agent_secret" {
#     name = "export-agent-secret.groovy"
#     data = file(("${path.module}/init.groovy.d/export-agent-secret.groovy"))
# }



resource "docker_service" "jenkins_controller" {
    name = "jenkins-controller"

    task_spec {
        container_spec {
        image = "ghcr.io/nodadyoushutup/jenkins-controller:2.516"

        env = {
            JAVA_OPTS = "-Djenkins.install.runSetupWizard=false"
            JENKINS_SECURITY_ADMIN_USERNAME = "admin"
            JENKINS_SECURITY_ADMIN_PASSWORD = "password"
            CASC_JENKINS_CONFIG = "/jenkins/casc_configs"
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

        configs {
            config_id   = docker_config.casc_appearance.id
            config_name = docker_config.casc_appearance.name
            file_name   = "/jenkins/casc_configs/appearance.yaml"
        }

        # configs {
        #     config_id   = docker_config.casc_credential.id
        #     config_name = docker_config.casc_credential.name
        #     file_name   = "/jenkins/casc_configs/credential.yaml"
        # }

        # configs {
        #     config_id   = docker_config.casc_jenkins.id
        #     config_name = docker_config.casc_jenkins.name
        #     file_name   = "/jenkins/casc_configs/jenkins.yaml"
        # }

        # configs {
        #     config_id   = docker_config.casc_unclassified.id
        #     config_name = docker_config.casc_unclassified.name
        #     file_name   = "/jenkins/casc_configs/unclassified.yaml"
        # }

        # configs {
        #     config_id   = docker_config.export_agent_secret.id
        #     config_name = docker_config.export_agent_secret.name
        #     file_name   = "/usr/share/jenkins/ref/init.groovy.d/export-agent-secret.groovy"
        # }

        dns_config {
            nameservers = ["1.1.1.1", "8.8.8.8"]
        }

        # 4) Make the healthcheck tolerant while Jenkins/JCasC is initializing
        healthcheck {
            # /login is public and doesn’t require a crumb or auth
            test         = ["CMD", "curl", "-fsS", "http://127.0.0.1:8080/login"]
            interval     = "10s"
            timeout      = "5s"
            retries      = 30
            start_period = "60s"
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

output "debug" {
  value = docker_service.jenkins_controller
}