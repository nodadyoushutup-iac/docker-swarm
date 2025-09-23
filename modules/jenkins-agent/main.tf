terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

resource "docker_volume" "agent" {
  name = "jenkins-agent-${var.name}"
}

resource "docker_config" "agent_entrypoint" {
  name = local.agent_entrypoint_config_name
  data = base64encode(file(local.resolved_agent_entrypoint_script_path))
}

resource "docker_service" "agent" {
  name = "jenkins-agent-${var.name}"

  task_spec {
    container_spec {
      image = "ghcr.io/nodadyoushutup/jenkins-agent:0.0.1"

      env = {
        JENKINS_URL = "http://192.168.1.44:8080"
        JENKINS_AGENT_NAME = var.name
      }

      mounts {
        target = "/home/jenkins"
        source = docker_volume.agent.name
        type   = "volume"
      }

      mounts {
        target = "/dev/kvm"
        source = "/dev/kvm"
        type   = "bind"
      }

      mounts {
        target = "/home/jenkins/.jenkins"
        source = pathexpand("~/.jenkins")
        type   = "bind"
      }

      mounts {
        target = "/home/jenkins/.ssh"
        source = pathexpand("~/.ssh")
        type   = "bind"
      }

      mounts {
        target = "/home/jenkins/.kube"
        source = pathexpand("~/.kube")
        type   = "bind"
      }

      mounts {
        target = "/home/jenkins/.tfvars"
        source = pathexpand("~/.tfvars")
        type   = "bind"
      }

      configs {
        config_id   = docker_config.agent_entrypoint.id
        config_name = docker_config.agent_entrypoint.name
        file_name   = "/agent-entrypoint.sh"
        file_mode   = 511
      }

      dns_config {
        nameservers = ["1.1.1.1", "8.8.8.8"]
      }

      command = ["/bin/sh", "-c", "/agent-entrypoint.sh"]
    }

    placement {
      platforms {
        os           = "linux"
        architecture = "arm64"
      }
    }
  }
}
