#!/usr/bin/env bash
# Watches configurations/glance/ for changes and restarts glance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCH_DIR="$SCRIPT_DIR/../configurations/glance"

echo "Watching $WATCH_DIR for changes..."

fswatch -o "$WATCH_DIR" | while read -r _; do
  echo "Change detected — restarting glance..."
  pkill glance 2>/dev/null || true
done
