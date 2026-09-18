#!/usr/bin/env bash
# Shim de compatibilidad para migrate-to-abbia.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
exec bash "$SCRIPT_DIR/migrate-to-abbia.sh" "$@"
