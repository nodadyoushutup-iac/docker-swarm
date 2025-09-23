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
