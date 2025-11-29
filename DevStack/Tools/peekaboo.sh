#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# TODO: customize once your Peekaboo tooling is reinstalled.
# Example assumptions:
# - peekaboo binary is on PATH
# - config file lives under DevStack/Tools/peekaboo.yml

PEEKABOO_CONFIG="$ROOT_DIR/DevStack/Tools/peekaboo.yml"

if ! command -v peekaboo >/dev/null 2>&1; then
  echo ">>> [peekaboo] ERROR: 'peekaboo' CLI not found on PATH."
  echo ">>> Install your Peekaboo tool and update this script accordingly."
  exit 1
fi

echo ">>> [peekaboo] Running visual regression checks"
peekaboo run --config "$PEEKABOO_CONFIG"
