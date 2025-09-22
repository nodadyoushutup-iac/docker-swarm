#!/usr/bin/env bash
set -euo pipefail

TFVARS_PATH="$HOME/.tfvars/docker_swarm.tfvars"
BACKEND_CONFIG_PATH="$HOME/.tfvars/minio.backend.hcl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

command -v terraform >/dev/null 2>&1 || { echo "[ERR] terraform not found in PATH" >&2; exit 127; }

echo "[STAGE 0] verify params"
[[ -n "$TFVARS_PATH" ]] || { echo "[ERR] TFVARS_PATH is not set" >&2; exit 1; }
[[ -f "$TFVARS_PATH" ]] || { echo "[ERR] TFVARS_PATH file not found: $TFVARS_PATH" >&2; exit 1; }
[[ -n "$BACKEND_CONFIG_PATH" ]] || { echo "[ERR] BACKEND_CONFIG_PATH is not set" >&2; exit 1; }
[[ -f "$BACKEND_CONFIG_PATH" ]] || { echo "[ERR] BACKEND_CONFIG_PATH file not found: $BACKEND_CONFIG_PATH" >&2; exit 1; }

apply_dir() {
  local TFVARS="$1"
  echo "[STEP] terraform init"
  terraform init -backend-config="$BACKEND_CONFIG_PATH"

  echo "[STEP] terraform plan"
  terraform plan -input=false ${TFVARS:+-var-file="$TFVARS"}

  echo "[STEP] terraform apply"
  terraform apply -input=false -auto-approve ${TFVARS:+-var-file="$TFVARS"}
}

echo "[STAGE 1] docker"
apply_dir "$TFVARS_PATH"

echo "[DONE] Apply complete."
