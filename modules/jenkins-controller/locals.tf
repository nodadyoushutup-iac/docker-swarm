locals {
  module_files_dir                   = "${path.module}/files"
  default_healthcheck_script_path    = "${local.module_files_dir}/healthcheck.sh"
  default_export_agent_secret_path   = "${local.module_files_dir}/init.groovy.d/export-agent-secret.groovy"

  resolved_healthcheck_script_path  = coalesce(var.healthcheck_script_path, local.default_healthcheck_script_path)
  resolved_export_agent_secret_path = coalesce(var.export_agent_secret_path, local.default_export_agent_secret_path)
}
