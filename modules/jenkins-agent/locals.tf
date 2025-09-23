locals {
  resolved_agent_entrypoint_script_path = coalesce(var.agent_entrypoint_script_path, "${path.root}/script/agent-entrypoint.sh")
  agent_entrypoint_config_name          = "agent-entrypoint-${var.name}.sh"
}
