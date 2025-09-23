#!/usr/bin/env bash
set -euo pipefail

# Docker reset that preserves swarm membership.
# Default: do NOT touch swarm tasks/services; purge standalone + all UNUSED artifacts.
# Optional: --drain (manager only) temporarily drains the node and purges EVERYTHING local, then restores availability.
# Optional: --restart restarts the docker service at the end (systemd).

WARN_VOL="This will remove UNUSED Docker volumes. Named volumes still attached to running containers (incl. swarm tasks) are preserved."
WARN_DRAIN="--drain will stop and remove ALL containers on this node (including swarm tasks). Services will reschedule elsewhere if possible."

force=true
drain=false
restart=false
services=true

usage() {
  cat <<EOF
Usage: $(basename "$0") [--force] [--drain] [--services] [--restart]

  --force     Skip interactive confirmation.
  --drain     (Manager node only) Temporarily set this node to DRAIN, stop/remove ALL containers,
              prune everything, then restore previous availability. Keeps node in the swarm.
  --services  (Manager node only) Remove ALL swarm services on this node after cleanup.
  --restart   Restart the Docker daemon at the end (systemd environments).

Notes:
- ${WARN_VOL}
- ${WARN_DRAIN}
EOF
}

for arg in "${@:-}"; do
  case "$arg" in
    --force)    force=true ;;
    --drain)    drain=true ;;
    --services) services=true ;;
    --restart)  restart=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1" >&2; exit 1; }; }

need_cmd docker
if [[ $restart == true ]]; then need_cmd systemctl; fi

echo "==> Docker info quick check..."
if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon doesn't look reachable. Is it running and do you have permissions?" >&2
  exit 1
fi

swarm_state=$(docker info --format '{{.Swarm.LocalNodeState}}' || echo "inactive")
is_in_swarm=false
[[ "$swarm_state" == "active" ]] && is_in_swarm=true

role="worker"
is_manager=false
if $is_in_swarm; then
  # ControlAvailable is true only on managers
  ctrl=$(docker info --format '{{.Swarm.ControlAvailable}}' || echo "false")
  [[ "$ctrl" == "true" ]] && { role="manager"; is_manager=true; }
fi

if $services && ! $is_manager; then
  echo "ERROR: --services requires running on a swarm MANAGER." >&2
  exit 1
fi

echo "==> Swarm: $($is_in_swarm && echo "JOINED ($role)" || echo "not joined")"

echo
echo "This will:"
echo "  • Stop & remove ALL standalone containers (not created by swarm)."
if $drain; then
  echo "  • (DRAIN MODE) Stop & remove ALL containers (including swarm tasks) on this node."
fi
if $services; then
  echo "  • Remove ALL swarm services."
fi
echo "  • Prune UNUSED images, volumes, networks, and builder cache."
echo "  • Preserve swarm membership (no 'docker swarm leave', no deletion of /var/lib/docker/swarm)."
echo
echo "Caveats:"
echo "  • ${WARN_VOL}"
$drain && echo "  • ${WARN_DRAIN}"
if $services; then
  echo "  • Removes all swarm services from the manager."
fi
echo

if [[ $force == false ]]; then
  read -r -p "Proceed? [y/N] " ans
  [[ "${ans:-}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

prev_avail=""
if $drain; then
  if ! $is_manager; then
    echo "ERROR: --drain requires running on a swarm MANAGER (to update node availability)." >&2
    exit 1
  fi
  echo "==> Capturing current node availability..."
  prev_avail=$(docker node inspect self --format '{{.Spec.Availability}}')
  echo "    Current availability: ${prev_avail}"
  if [[ "$prev_avail" != "drain" ]]; then
    echo "==> Draining node to prevent new task scheduling here..."
    docker node update --availability drain self
  else
    echo "    Node already in DRAIN."
  fi
fi

echo "==> Killing containers..."
if $drain; then
  # Stop & remove everything
  mapfile -t all_cids < <(docker ps -aq)
  if (( ${#all_cids[@]} )); then
    docker rm -f "${all_cids[@]}"
  else
    echo "    No containers present."
  fi
else
  # Only non-swarm tasks
  mapfile -t stand_cids < <(docker ps -aq --filter "is-task=false")
  if (( ${#stand_cids[@]} )); then
    docker rm -f "${stand_cids[@]}"
  else
    echo "    No standalone containers present."
  fi
fi

echo "==> Removing old/stopped builder containers (if any)..."
docker ps -aq --filter "status=exited" --filter "status=dead" | xargs -r docker rm -f

echo "==> Pruning images (unused & dangling)..."
docker image prune -af || true

echo "==> Pruning build cache (BuildKit/buildx)..."
# Buildx prune is safe even if buildx isn't configured explicitly
docker buildx prune -af || true
# Legacy builder cache (no-op on recent setups, safe to try)
docker builder prune -af || true

echo "==> Pruning networks (unused only; default & in-use overlays preserved)..."
docker network prune -f || true

echo "==> Pruning volumes (UNUSED only; volumes attached to running containers are preserved)..."
docker volume prune -f || true

echo "==> System prune (leftover junk: containers, images, networks, build cache)..."
docker system prune -af || true

# Optional: clear dangling images on older engines one more time
docker images -f dangling=true -q | xargs -r docker rmi -f || true

if $drain; then
  if [[ -n "$prev_avail" && "$prev_avail" != "drain" ]]; then
    echo "==> Restoring node availability to: ${prev_avail}"
    docker node update --availability "$prev_avail" self
  else
    echo "==> Leaving node availability in DRAIN (explicit or unchanged)."
  fi
fi

if $services; then
  echo "==> Removing swarm services..."
  mapfile -t svc_ids < <(docker service ls -q)
  if (( ${#svc_ids[@]} )); then
    docker service rm "${svc_ids[@]}"
  else
    echo "    No swarm services present."
  fi
fi

if $restart; then
  echo "==> Restarting Docker daemon..."
  sudo systemctl restart docker
fi

echo "==> Done. Swarm membership preserved."
