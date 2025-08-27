# # resource "jenkins_job" "cloud_image" {
# #   name = "cloud-image"
# #   template = templatefile("${path.module}/job.xml", {
# #     description = "A cloud_image job created with Packer"
# #     project_url = "https://github.com/nodadyoushutup/cloud-image"
# #     scm_repository_url = "https://github.com/nodadyoushutup/cloud-image"
# #     script_path = "pipeline.jenkins"
# #   })
# # }

# # resource "jenkins_job" "terraform_proxmox" {
# #   name = "terraform-proxmox"
# #   template = templatefile("${path.module}/job.xml", {
# #     description = "Proxmox assets"
# #     project_url = "https://github.com/nodadyoushutup/terraform-proxmox"
# #     scm_repository_url = "https://github.com/nodadyoushutup/terraform-proxmox"
# #     script_path = "pipeline.jenkins"
# #   })
# # }

# ############################################
# # volumes
# ############################################
# resource "docker_volume" "jenkins_controller" {
#   name = "jenkins-controller"
# }

# resource "docker_volume" "jenkins_agent" {
#   name = "jenkins-agent"
# }

# ############################################
# # locals
# ############################################
# locals {
#   jenkins_url = lookup(var.jenkins_controller_env, "JENKINS_LOCATION_URL", "http://localhost:8080")
# }

# ############################################
# # jenkins-controller
# ############################################
# resource "docker_service" "jenkins_controller" {
#   name = "jenkins-controller"

#   task_spec {
#     container_spec {
#       image = "ghcr.io/nodadyoushutup/jenkins-controller:2.516"
#       env = var.jenkins_controller_env
#       groups = [var.kvm_gid]
#       dns_config {
#         nameservers = ["1.1.1.1", "8.8.8.8"]
#       }
#       mounts {
#         target = "/dev/kvm"
#         source = "/dev/kvm"
#         type   = "bind"
#       }
#       mounts {
#         target = "/var/jenkins_home"
#         source = docker_volume.jenkins_controller.name
#         type   = "volume"
#       }

#       mounts {
#         target = "/usr/share/jenkins/ref/init.groovy.d"
#         source = var.init_groovy_dir   # ABSOLUTE host path
#         type   = "bind"
#       }

#       mounts {
#         target = "/jenkins/casc_configs"
#         source = var.casc_configs_dir  # ABSOLUTE host path
#         type   = "bind"
#       }

#       mounts {
#         target = "/secrets"
#         source = var.secrets_dir       # ABSOLUTE host path
#         type   = "bind"
#       }

#       healthcheck {
#         test     = ["CMD", "curl", "-f", "${local.jenkins_url}/whoAmI/api/json?tree=authenticated"]
#         interval = "5s"
#         retries  = 12
#       }
#     }

#     restart_policy {
#       condition = "any"
#       delay     = "5s"
#     }
#   }

#   endpoint_spec {
#     # compose: ports: "8080:8080", "50000:50000"
#     ports {
#       target_port    = 8080
#       published_port = 8080
#       publish_mode   = "ingress"
#     }
#     ports {
#       target_port    = 50000
#       published_port = 50000
#       publish_mode   = "ingress"
#     }
#   }
# }

# ############################################
# # jenkins-agent
# ############################################
# resource "docker_service" "jenkins_agent" {
#   name = "jenkins-agent"

#   task_spec {
#     container_spec {
#       image = var.jenkins_agent_image

#       env = var.jenkins_agent_env
#       groups = [var.kvm_gid]

#       dns_config {
#         nameservers = ["1.1.1.1", "8.8.8.8"]
#       }

#       # compose: entrypoint: ["/scripts/agent-entrypoint.sh"]
#       # swarm uses "command" to override entrypoint
#       command = ["/scripts/agent-entrypoint.sh"]

#       # devices -> bind as above
#       mounts {
#         target = "/dev/kvm"
#         source = "/dev/kvm"
#         type   = "bind"
#       }

#       # volumes:
#       mounts {
#         target = "/home/jenkins"
#         source = docker_volume.jenkins_agent.name
#         type   = "volume"
#       }

#       mounts {
#         target = "/scripts"
#         source = var.scripts_dir       # ABSOLUTE host path
#         type   = "bind"
#       }

#       mounts {
#         target = "/secrets"
#         source = var.secrets_dir       # ABSOLUTE host path (shared with controller)
#         type   = "bind"
#       }
#     }

#     restart_policy {
#       condition = "any"
#       delay     = "5s"
#     }
#   }

#   # Swarm doesn't support compose's depends_on. The agent entrypoint should handle waiting/retrying.
# }

# ############################################
# # dozzle
# ############################################
# resource "docker_service" "dozzle" {
#   name = "dozzle"

#   task_spec {
#     container_spec {
#       image = var.dozzle_image

#       # bind docker.sock (works well on single-node swarm)
#       mounts {
#         target = "/var/run/docker.sock"
#         source = "/var/run/docker.sock"
#         type   = "bind"
#       }

#       dns_config {
#         nameservers = ["1.1.1.1", "8.8.8.8"]
#       }

#       healthcheck {
#         test     = ["CMD", "/dozzle", "healthcheck"]
#         interval = "5s"
#         retries  = 12
#       }
#     }

#     restart_policy {
#       condition = "any"
#       delay     = "5s"
#     }
#   }

#   endpoint_spec {
#     ports {
#       target_port    = 8080
#       published_port = 8081
#       publish_mode   = "ingress"
#     }
#   }
# }
