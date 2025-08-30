variable "name" {
  description = "Name of the Jenkins agent"
  type        = string
}

variable "jenkins_url" {
  description = "URL of the Jenkins controller"
  type        = string
}

variable "agent_entrypoint_config_id" {
  description = "ID of the Docker config containing the agent entrypoint script"
  type        = string
}

variable "agent_entrypoint_config_name" {
  description = "Name of the Docker config containing the agent entrypoint script"
  type        = string
}
