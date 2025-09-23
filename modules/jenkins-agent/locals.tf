locals {
  module_files_dir                      = "${path.module}/files"
  default_agent_entrypoint_script_path  = "${local.module_files_dir}/agent-entrypoint.sh"

  resolved_agent_entrypoint_script_path = coalesce(var.agent_entrypoint_script_path, local.default_agent_entrypoint_script_path)
  agent_entrypoint_config_name          = "agent-entrypoint-${var.name}.sh"
}
