terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

variable "casc_config" {
  description = "Configuration as Code data structure for the Jenkins controller"
  type        = any
}

variable "controller_name" {
  description = "Name for the Jenkins controller service and associated resources"
  type        = string
  default     = "jenkins-controller"
}

variable "controller_image" {
  description = "Container image to deploy for the Jenkins controller"
  type        = string
  default     = "ghcr.io/nodadyoushutup/jenkins-controller:0.0.1"
}

variable "admin_username" {
  description = "Username for the Jenkins administrator account"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Password for the Jenkins administrator account"
  type        = string
  default     = "password"
}

variable "healthcheck_endpoint" {
  description = "Endpoint used by the local healthcheck script to verify the controller is online"
  type        = string
}

variable "healthcheck_delay_seconds" {
  description = "Delay between healthcheck attempts"
  type        = number
  default     = 5
}

variable "healthcheck_max_attempts" {
  description = "Maximum number of healthcheck attempts"
  type        = number
  default     = 60
}

variable "healthcheck_timeout_seconds" {
  description = "Timeout for each healthcheck attempt"
  type        = number
  default     = 5
}

variable "dns_nameservers" {
  description = "DNS servers used by the Jenkins controller container"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "healthcheck_script_path" {
  description = "Path to the script that validates the Jenkins controller health"
  type        = string
  default     = null
}

variable "export_agent_secret_path" {
  description = "Path to the Groovy script responsible for exporting the agent secret"
  type        = string
  default     = null
}

variable "casc_config_name" {
  description = "Name used for the Jenkins Configuration as Code docker config"
  type        = string
  default     = "casc-config.yaml"
}

variable "export_agent_secret_name" {
  description = "Name used for the Groovy docker config that exports the agent secret"
  type        = string
  default     = "export-agent-secret.groovy"
}

locals {
  resolved_healthcheck_script_path = coalesce(var.healthcheck_script_path, "${path.root}/script/healthcheck.sh")
  resolved_export_agent_secret_path = coalesce(var.export_agent_secret_path, "${path.root}/init.groovy.d/export-agent-secret.groovy")
}

resource "docker_volume" "controller" {
  name = var.controller_name
}

resource "docker_config" "casc_config" {
  name = var.casc_config_name
  data = base64encode(yamlencode(var.casc_config))
}

resource "docker_config" "export_agent_secret" {
  name = var.export_agent_secret_name
  data = base64encode(file(local.resolved_export_agent_secret_path))
}

resource "docker_service" "controller" {
  name = var.controller_name

  task_spec {
    container_spec {
      image = var.controller_image

      env = {
        JAVA_OPTS                       = "-Djenkins.install.runSetupWizard=false"
        JENKINS_SECURITY_ADMIN_USERNAME = var.admin_username
        JENKINS_SECURITY_ADMIN_PASSWORD = var.admin_password
        CASC_JENKINS_CONFIG             = "/jenkins/casc_configs"
      }

      mounts {
        target = "/var/jenkins_home"
        source = docker_volume.controller.name
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
        nameservers = var.dns_nameservers
      }

      healthcheck {
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
  depends_on = [docker_service.controller]

  triggers = {
    endpoint     = var.healthcheck_endpoint
    delay        = tostring(var.healthcheck_delay_seconds)
    max_attempts = tostring(var.healthcheck_max_attempts)
    script_sha1  = filesha1(local.resolved_healthcheck_script_path)
  }

  provisioner "local-exec" {
    command = "MAX_ATTEMPTS=${var.healthcheck_max_attempts} TIMEOUT=${var.healthcheck_timeout_seconds} bash ${local.resolved_healthcheck_script_path} ${var.healthcheck_endpoint} ${var.healthcheck_delay_seconds}"
  }
}

output "service_id" {
  description = "ID of the Jenkins controller docker service"
  value       = docker_service.controller.id
}

output "wait_for_service_id" {
  description = "ID of the null resource waiting for the controller service"
  value       = null_resource.wait_for_service.id
}
