#!/usr/bin/env bash
set -euo pipefail

AUTO_APPROVE=false

usage() {
  cat <<'EOF'
Usage:
  ./pipeline.sh [--auto-approve] [service]

Runs: terraform init → terraform plan → terraform apply

Behavior:
  - If no service is given: use the single *.tfvars in the current directory.
  - If service is given: use $HOME/.tfvars/<service>.tfvars
  - Passing an explicit *.tfvars path is NOT allowed.

Options:
  --auto-approve  Pass -auto-approve to 'terraform apply' (non-interactive)
  -h, --help      Show this help

Notes:
- By default this script prompts on apply.
- If TF_CLI_ARGS_apply contains -auto-approve, Terraform would normally skip the prompt.
  In interactive mode, this script temporarily removes that flag so you still get a prompt.
EOF
}

# Parse flags first
while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-approve) AUTO_APPROVE=true; shift ;;
    -h|--help)      usage; exit 0 ;;
    --)             shift; break ;;
    -*)             echo "[ERR] Unknown option: $1" >&2; usage; exit 2 ;;
    *)              break ;;
  esac
done

# Disallow more than one positional argument
if [[ $# -gt 1 ]]; then
  echo "[ERR] Too many arguments. Only an optional 'service' is allowed." >&2
  usage
  exit 2
fi

SERVICE=""
VAR_FILE=""

# Helper: find exactly one *.tfvars in CWD
pick_single_tfvars_in_cwd() {
  local matches=()
  while IFS= read -r f; do matches+=("$f"); done < <(compgen -G "*.tfvars" || true)
  if [[ ${#matches[@]} -eq 1 ]]; then
    printf '%s\n' "${matches[0]}"
    return 0
  elif [[ ${#matches[@]} -eq 0 ]]; then
    echo "[ERR] No *.tfvars found in current directory. Provide a service. " \
         "Example: ./pipeline.sh proxmox" >&2
    return 1
  else
    echo "[ERR] Multiple *.tfvars found in current directory:" >&2
    printf '  - %s\n' "${matches[@]}" >&2
    echo "[ERR] Please specify a service instead. Example: ./pipeline.sh proxmox" >&2
    return 1
  fi
}

# Resolve positional
if [[ $# -eq 0 ]]; then
  VAR_FILE="$(pick_single_tfvars_in_cwd)" || exit 2
else
  SERVICE="$1"
  if [[ "$SERVICE" == *.tfvars ]]; then
    echo "[ERR] Explicit .tfvars paths are not allowed. Pass a service name instead." >&2
    exit 2
  fi
  VAR_FILE="$HOME/.tfvars/${SERVICE}.tfvars"
fi

# Pre-flight checks
command -v terraform >/dev/null 2>&1 || { echo "[ERR] terraform not found in PATH" >&2; exit 127; }
[[ -f "$VAR_FILE" ]] || { echo "[ERR] var-file not found: $VAR_FILE" >&2; exit 1; }

echo "[INFO] Service  : ${SERVICE:-<none>}"
echo "[INFO] Var file : $VAR_FILE"

echo "[STEP] terraform init"
terraform init -input=false

if $AUTO_APPROVE; then
  PLAN_DIR="$(mktemp -d -t tfplan.XXXXXX)"
  PLAN_FILE="${PLAN_DIR}/plan.tfplan"
  cleanup() { rm -rf "$PLAN_DIR" >/dev/null 2>&1 || true; }
  trap cleanup EXIT

  echo "[STEP] terraform plan -> $PLAN_FILE"
  terraform plan -input=false -var-file="$VAR_FILE" -out="$PLAN_FILE"

  echo "[STEP] terraform apply (auto-approve)"
  terraform apply -input=false -auto-approve "$PLAN_FILE"
else
  echo "[STEP] terraform plan"
  terraform plan -input=false -var-file="$VAR_FILE"

  echo "[STEP] terraform apply (will prompt)"
  if [[ "${TF_CLI_ARGS_apply:-}" == *"-auto-approve"* ]]; then
    echo "[WARN] TF_CLI_ARGS_apply contains -auto-approve; temporarily removing so you get a prompt."
    TF_CLI_ARGS_apply="${TF_CLI_ARGS_apply//-auto-approve/}" terraform apply -var-file="$VAR_FILE"
  else
    terraform apply -var-file="$VAR_FILE"
  fi
fi

echo "[DONE] Apply complete."
