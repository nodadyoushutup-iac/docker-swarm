#!/usr/bin/env bash
set -euo pipefail

DOCKER_TFVARS="$HOME/.tfvars/docker/jenkins.tfvars"
APP_TFVARS="$HOME/.tfvars/jenkins.tfvars"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

usage() {
  cat <<'EOT'
Usage:
  ./pipeline.sh [--docker-tfvars FILE] [--jenkins-tfvars FILE]

Runs terraform init/plan/apply for:
  1. docker/
  2. jenkins/

Options:
  --docker-tfvars FILE   Pass -var-file=FILE when running in docker/
  --jenkins-tfvars FILE  Pass -var-file=FILE when running in jenkins/
  -h, --help             Show this help
EOT
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --docker-tfvars) DOCKER_TFVARS="$2"; shift 2 ;;
    --jenkins-tfvars) APP_TFVARS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "[ERR] Unknown option: $1" >&2; usage; exit 2 ;;
    *)  echo "[ERR] Unexpected argument: $1" >&2; usage; exit 2 ;;
  esac
done

command -v terraform >/dev/null 2>&1 || { echo "[ERR] terraform not found in PATH" >&2; exit 127; }

echo "[STAGE 0] verify params"
[[ -n "$DOCKER_TFVARS" ]] || { echo "[ERR] DOCKER_TFVARS is not set" >&2; exit 1; }
[[ -f "$DOCKER_TFVARS" ]] || { echo "[ERR] DOCKER_TFVARS file not found: $DOCKER_TFVARS" >&2; exit 1; }
[[ -n "$APP_TFVARS" ]] || { echo "[ERR] APP_TFVARS is not set" >&2; exit 1; }
[[ -f "$APP_TFVARS" ]] || { echo "[ERR] APP_TFVARS file not found: $APP_TFVARS" >&2; exit 1; }

apply_dir() {
  local DIR="$1"
  local TFVARS="$2"
  echo "[STEP] terraform -chdir=${DIR} init"
  terraform -chdir="$DIR" init -input=false

  echo "[STEP] terraform -chdir=${DIR} plan"
  terraform -chdir="$DIR" plan -input=false ${TFVARS:+-var-file="$TFVARS"}

  echo "[STEP] terraform -chdir=${DIR} apply"
  terraform -chdir="$DIR" apply -input=false -auto-approve ${TFVARS:+-var-file="$TFVARS"}
}

echo "[STAGE 1] docker"
apply_dir "${ROOT_DIR}/docker" "$DOCKER_TFVARS"

echo "[STAGE 2] jenkins"
# apply_dir "${ROOT_DIR}/jenkins" "$APP_TFVARS" #TEMP COMMENT

echo "[DONE] Apply complete."
