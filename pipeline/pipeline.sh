#!/usr/bin/env bash
set -euo pipefail

command -v terraform >/dev/null 2>&1 || { echo "[ERR] terraform not found in PATH" >&2; exit 127; }
command -v realpath  >/dev/null 2>&1 || { echo "[ERR] realpath not found in PATH" >&2; exit 127; }

echo "Starting pipeline"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TFVARS_PATH="$(realpath "${HOME}/.tfvars/docker_swarm.tfvars")"
BACKEND_CONFIG_PATH="$(realpath "${HOME}/.tfvars/minio.backend.hcl")"

[ -f "${TFVARS_PATH}" ] || { echo "[ERR] Missing ${TFVARS_PATH}" >&2; exit 1; }
[ -f "${BACKEND_CONFIG_PATH}" ] || { echo "[ERR] Missing ${BACKEND_CONFIG_PATH}" >&2; exit 1; }

cd "${ROOT_DIR}"

echo "[STEP] terraform init"
terraform init -backend-config="${BACKEND_CONFIG_PATH}"

echo "[STEP] terraform plan"
terraform plan -input=false -var-file="${TFVARS_PATH}"

echo "[STEP] terraform apply"
terraform apply -input=false -auto-approve -var-file="${TFVARS_PATH}"

echo "[DONE] Apply complete."
