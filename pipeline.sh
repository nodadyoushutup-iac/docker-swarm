#!/usr/bin/env bash
set -euo pipefail

AUTO_APPROVE=false

usage() {
  cat <<'EOT'
Usage:
  ./pipeline.sh [--auto-approve]

Runs terraform init/plan/apply for:
  1. docker/
  2. jenkins/

Options:
  --auto-approve  Pass -auto-approve to 'terraform apply' (non-interactive)
  -h, --help      Show this help
EOT
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-approve) AUTO_APPROVE=true; shift ;;
    -h|--help)      usage; exit 0 ;;
    --)             shift; break ;;
    -*)             echo "[ERR] Unknown option: $1" >&2; usage; exit 2 ;;
    *)              echo "[ERR] Unexpected argument: $1" >&2; usage; exit 2 ;;
  esac
done

command -v terraform >/dev/null 2>&1 || { echo "[ERR] terraform not found in PATH" >&2; exit 127; }

apply_dir() {
  local DIR="$1"
  echo "[STEP] terraform -chdir=${DIR} init"
  terraform -chdir="$DIR" init -input=false

  if $AUTO_APPROVE; then
    echo "[STEP] terraform -chdir=${DIR} apply (auto-approve)"
    terraform -chdir="$DIR" apply -input=false -auto-approve
  else
    echo "[STEP] terraform -chdir=${DIR} plan"
    terraform -chdir="$DIR" plan -input=false
    echo "[STEP] terraform -chdir=${DIR} apply (will prompt)"
    if [[ "${TF_CLI_ARGS_apply:-}" == *"-auto-approve"* ]]; then
      echo "[WARN] TF_CLI_ARGS_apply contains -auto-approve; temporarily removing so you get a prompt."
      TF_CLI_ARGS_apply="${TF_CLI_ARGS_apply//-auto-approve/}" terraform -chdir="$DIR" apply
    else
      terraform -chdir="$DIR" apply
    fi
  fi
}

apply_dir docker
apply_dir jenkins

echo "[DONE] Apply complete."
