#!/usr/bin/env bash
set -euo pipefail

# 🚨 WARNING 🚨
# This script forcefully deletes ALL Docker containers, images, volumes, services, and swarm configs.
# It does NOT remove this node from the swarm.
# It also PRESERVES all Docker networks (default + custom).
# Use with extreme caution.

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }; }
need_cmd docker

echo "==> Purging EVERYTHING Docker (except swarm membership and networks)..."

# Stop and remove all containers (swarm tasks + standalone)
echo "==> Killing all containers..."
docker ps -aq | xargs -r docker rm -f

# Remove all services (but keep swarm join state)
echo "==> Removing swarm services..."
docker service ls -q | xargs -r docker service rm

# Remove all swarm configs
echo "==> Removing swarm configs..."
docker config ls -q | xargs -r docker config rm || true

# Remove all images
echo "==> Removing images..."
docker images -aq | xargs -r docker rmi -f || true

# Remove all volumes
echo "==> Removing volumes..."
docker volume ls -q | xargs -r docker volume rm -f || true

# Remove build cache (buildx + legacy)
echo "==> Clearing build cache..."
docker builder prune -af || true
docker buildx prune -af || true

# System prune (final sweep, but WITHOUT networks)
echo "==> Final system prune (keeping networks)..."
docker system prune -af || true

echo "==> Docker purge complete. Swarm membership and all networks preserved."
