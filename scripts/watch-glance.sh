#!/usr/bin/env bash
# Watches configurations/glance/ for changes and restarts glance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCH_DIR="$SCRIPT_DIR/../services/glance"

echo "Watching $WATCH_DIR for changes..."

fswatch -o --latency 0.5 -e ".*" -i "\.yml$" -i "\.css$" "$WATCH_DIR" | while read -r _; do
  echo "Change detected — restarting glance..."
  container stop glance
done
