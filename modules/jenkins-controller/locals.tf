locals {
  resolved_healthcheck_script_path    = coalesce(var.healthcheck_script_path, "${path.root}/script/healthcheck.sh")
  resolved_export_agent_secret_path   = coalesce(var.export_agent_secret_path, "${path.root}/init.groovy.d/export-agent-secret.groovy")
}
