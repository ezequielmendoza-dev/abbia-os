#!/usr/bin/env bash

# ==============================================================================
# common.sh — ai-agents OS Shared Utilities
# ==============================================================================
# Archivo de utilidades compartidas para evitar duplicidad de código.
# ==============================================================================

# Evitar doble inclusión
if [ -n "${AI_AGENTS_COMMON_LOADED:-}" ]; then
    return 0
fi
AI_AGENTS_COMMON_LOADED=1

# Colores para la consola
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

# Rutas base comunes
# Nota: Cada script debe definir SCRIPT_DIR antes de hacer source de este archivo
if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

AI_AGENTS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CWD="$(pwd)"

# ---------- Iniciativas: tipos y patrón de nomenclatura ----------
# Tipos de iniciativa soportados en .ai/features/ y .ai/archive/.
# - FEAT: feature | BUG: corrección | AUDIT: auditoría/seguridad | REF: refactor
INITIATIVE_TYPES="FEAT BUG AUDIT REF"

# Patrón central de nomenclatura: <TIPO>-<ID 3 dígitos>-<slug>
# Se construye dinámicamente desde INITIATIVE_TYPES.
initiative_name_pattern() {
    printf '^(%s)-[0-9]{3}-[a-z0-9-]+$' "$(echo "$INITIATIVE_TYPES" | tr ' ' '|')"
}

# Devuelve los archivos obligatorios para un tipo (vacío = estructura libre).
# Uso: required_files_for <FEAT|BUG|AUDIT|REF>
required_files_for() {
    case "$1" in
        FEAT) echo "spec.md ui-design.md architecture.md qa.md decision.md" ;;
        BUG)  echo "bug-report.md qa.md" ;;
        *)    echo "" ;;   # AUDIT y REF: estructura libre
    esac
}

# Versión legible del patrón de tipos para mensajes: FEAT|BUG|AUDIT|REF
initiative_types_readable() {
    echo "$INITIATIVE_TYPES" | tr ' ' '|'
}

# Función para detectar la raíz del proyecto
detect_project_root() {
    if [ -d "$CWD/.ai" ]; then
        echo "$CWD"
    elif [ -d "$CWD/../.ai" ]; then
        (cd "$CWD/.." && pwd)
    elif [ -d "$CWD/../../.ai" ]; then
        (cd "$CWD/../.." && pwd)
    elif [ -d "$CWD/.ai/agents" ]; then
        echo "$CWD"
    else
        echo "$CWD"
    fi
}
