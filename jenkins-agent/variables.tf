variable "name" {
  description = "Name of the Jenkins agent"
  type        = string
}

variable "jenkins_url" {
  description = "URL of the Jenkins controller"
  type        = string
}

variable "agent_entrypoint_script_path" {
  description = "Path to the Jenkins agent entrypoint script (defaults to module-provided script)"
  type        = string
  default     = null
}
