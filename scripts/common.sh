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

# Devuelve los archivos obligatorios de inicio para un tipo (activos en .ai/features/).
# Uso: required_files_for <FEAT|BUG|AUDIT|REF>
required_files_for() {
    case "$1" in
        FEAT) echo "spec.md decision.md" ;;
        BUG)  echo "bug-report.md" ;;
        *)    echo "" ;;   # AUDIT y REF: estructura libre
    esac
}

# Devuelve los archivos obligatorios que deben existir al completar/archivar una iniciativa.
# Uso: required_archived_files_for <FEAT|BUG|AUDIT|REF>
required_archived_files_for() {
    case "$1" in
        FEAT) echo "spec.md architecture.md qa.md decision.md" ;;
        BUG)  echo "bug-report.md qa.md" ;;
        *)    echo "" ;;
    esac
}

# Versión legible del patrón de tipos para mensajes: FEAT|BUG|AUDIT|REF
initiative_types_readable() {
    echo "$INITIATIVE_TYPES" | tr ' ' '|'
}

# Patrón de ID de iniciativa sin slug: <TIPO>-<NNN> (ej: FEAT-114)
initiative_id_pattern() {
    printf '^(%s)-[0-9]{3}$' "$(echo "$INITIATIVE_TYPES" | tr ' ' '|')"
}

# Roles del pipeline que cierran fases y registran ejecuciones en metrics
AGENT_ROLES="analyst ui-designer architect developer qa tech-lead devops"

# Re-genera .ai/memory/context-snapshot.md compactando workflow-log + knowledge-graph/decisions + patterns.
# Uso: regenerate_context_snapshot <PROJECT_ROOT>  (destructivo: reescribe el snapshot)
regenerate_context_snapshot() {
    local project_root="${1:-$CWD}"
    local mem_dir="$project_root/.ai/memory"
    local log="$mem_dir/workflow-log.md"
    local kg_file="$project_root/.ai/knowledge-graph.yaml"
    local dec_file="$project_root/.ai/decisions.md"
    local patterns="$mem_dir/patterns-learned.md"
    local out="$mem_dir/context-snapshot.md"

    # --- Últimas entradas del workflow-log (hasta 8) ---
    local recent=""
    if [ -f "$log" ]; then
        recent=$(grep -E '^## \[(FEAT|BUG|AUDIT|REF)-[0-9]{3}\]' "$log" | tail -8 || true)
    fi
    if [ -z "$recent" ]; then
        recent="(sin entradas aún en workflow-log.md)"
    fi

    # --- Decisiones vigentes (desde knowledge-graph.yaml o fallback decisions.md) ---
    local decisions=""
    if [ -f "$kg_file" ]; then
        decisions=$(awk '
            /^[[:space:]]*- id:[[:space:]]*(ARCH-[0-9]{3})/ {
                match($0, /ARCH-[0-9]{3}/); id=substr($0, RSTART, RLENGTH); title=""
            }
            /^[[:space:]]*title:[[:space:]]*/ {
                gsub(/^[[:space:]]*title:[[:space:]]*["\047]?|["\047]?[[:space:]]*$/, "");
                title=$0
                if (id != "" && title != "" && title != "Nombre corto de la decisión") {
                    print "- **" id "**: " title
                    id=""; title=""
                }
            }
        ' "$kg_file" | tail -8 || true)
    fi

    if [ -z "$decisions" ] && [ -f "$dec_file" ]; then
        decisions=$(grep -E '^## \[(ARCH|DEC)-[0-9]{3}\]' "$dec_file" | grep -v 'ARCH-001\] Decisión de Arquitectura Inicial' | sed 's/^## /- /' | tail -8 || true)
    fi

    if [ -z "$decisions" ]; then
        decisions="(sin decisiones registradas en knowledge-graph.yaml o decisions.md)"
    fi

    # --- Patrones aprendidos (encabezados ##, sin el template Problema:) ---
    local pats=""
    if [ -f "$patterns" ]; then
        pats=$(grep -E '^## ' "$patterns" | grep -v '^## Problema:' | tail -5 || true)
    fi
    if [ -z "$pats" ]; then
        pats="(sin patrones aún en patterns-learned.md)"
    fi

    cat > "$out" << EOF
# Context Snapshot — Memoria Compactada

> Generado automáticamente por finish-phase.sh al cerrar una fase.
> Compacta \`workflow-log.md\` + \`knowledge-graph.yaml\` + \`patterns-learned.md\` —
> **no se edita a mano**. Máximo ~30-50 líneas.

## Estado del proyecto

Últimas fases cerradas:

$recent

## Decisiones vigentes

$decisions

## Patrones relevantes

$pats

EOF

    # --- Resumen de métricas (últimas sesiones de executions.yaml) ---
    local metrics_file="$project_root/.ai/metrics/executions.yaml"
    if [ -f "$metrics_file" ]; then
        local total_sessions=0
        local null_tokens=0
        local measured_sessions=0
        # Garantizar que son números enteros simples de una sola línea
        total_sessions=$( (grep -c '^\s*- ts:' "$metrics_file" 2>/dev/null || true) | tr -cd '0-9' )
        null_tokens=$( (grep -c '^\s*tokens_in: null' "$metrics_file" 2>/dev/null || true) | tr -cd '0-9' )
        total_sessions=${total_sessions:-0}
        null_tokens=${null_tokens:-0}
        measured_sessions=$(( total_sessions - null_tokens ))
        local warn_line=""
        if [ "$null_tokens" -gt 0 ] 2>/dev/null; then
            warn_line="> ⚠ Hay ${null_tokens} sesión(es) sin telemetría real. Pasá \`--tokens-in <N> --tokens-out <N> --source measured\` al llamar \`finish-phase.sh\`."
        fi
        cat >> "$out" << EOF
## Métricas de telemetría

- Total sesiones registradas: **$total_sessions**
- Con tokens medidos: **$measured_sessions** | Sin tokens (null): **$null_tokens**
$warn_line

Referencia: docs/agent-metrics.md (framework ai-agents).
EOF
    else
        cat >> "$out" << EOF
## Métricas de telemetría

> Sin datos en .ai/metrics/executions.yaml aún.

Referencia: docs/agent-metrics.md (framework ai-agents).
EOF
    fi
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
