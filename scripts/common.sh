#!/usr/bin/env bash

# ==============================================================================
# common.sh — Abbia OS Shared Utilities
# ==============================================================================
# Archivo de utilidades compartidas para el framework Abbia OS (v4.0.0).
# Soporta la estructura canónica .abbia/ y provee retrocompatibilidad con .stratum/ y .ai/.
# ==============================================================================

# Evitar doble inclusión
if [ -n "${ABBIA_COMMON_LOADED:-}" ]; then
    return 0
fi
ABBIA_COMMON_LOADED=1
STRATUM_COMMON_LOADED=1   # retrocompatibilidad
AI_AGENTS_COMMON_LOADED=1 # retrocompatibilidad

# Metadatos de Abbia OS
ABBIA_NAME="Abbia OS"
ABBIA_VERSION="v4.0.0"
ABBIA_MOTTO="Layered Context, Structured Memory, Autonomous Delivery"

# Alias retrocompatibles
STRATUM_NAME="$ABBIA_NAME"
STRATUM_VERSION="$ABBIA_VERSION"
STRATUM_MOTTO="$ABBIA_MOTTO"

# Colores para la consola
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Rutas base comunes
if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

ABBIA_CORE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STRATUM_CORE_ROOT="$ABBIA_CORE_ROOT" # alias retrocompatible
AI_AGENTS_ROOT="$ABBIA_CORE_ROOT"   # alias retrocompatible
CWD="$(pwd)"

# Función para detectar la raíz del proyecto
detect_project_root() {
    local curr="$CWD"
    while [ "$curr" != "/" ] && [ "$curr" != "." ]; do
        if [ -d "$curr/.abbia" ] || [ -d "$curr/.stratum" ] || [ -d "$curr/.ai" ] || [ -f "$curr/.gitmodules" ]; then
            echo "$curr"
            return 0
        fi
        curr="$(dirname "$curr")"
    done
    echo "$CWD"
}

# Resolver rutas del entorno Abbia en el proyecto destino
resolve_abbia_paths() {
    local root="${1:-$(detect_project_root)}"
    PROJECT_ROOT="$root"

    if [ -d "$root/.abbia" ]; then
        ABBIA_DIR="$root/.abbia"
        ABBIA_IS_LEGACY=false
    elif [ -d "$root/.stratum" ]; then
        ABBIA_DIR="$root/.stratum"
        ABBIA_IS_LEGACY=true
    elif [ -d "$root/.ai" ]; then
        ABBIA_DIR="$root/.ai"
        ABBIA_IS_LEGACY=true
    else
        # Por defecto para inicializaciones nuevas
        ABBIA_DIR="$root/.abbia"
        ABBIA_IS_LEGACY=false
    fi

    # Submódulo / core
    if [ -d "$ABBIA_DIR/core" ]; then
        ABBIA_CORE="$ABBIA_DIR/core"
    elif [ -d "$ABBIA_DIR/agents" ]; then
        ABBIA_CORE="$ABBIA_DIR/agents"
    else
        ABBIA_CORE="$ABBIA_DIR/core"
    fi

    # Directorio de iniciativas (soporta initiatives y features)
    if [ -d "$ABBIA_DIR/initiatives" ]; then
        ABBIA_INITIATIVES_DIR="$ABBIA_DIR/initiatives"
    elif [ -d "$ABBIA_DIR/features" ]; then
        ABBIA_INITIATIVES_DIR="$ABBIA_DIR/features"
    else
        ABBIA_INITIATIVES_DIR="$ABBIA_DIR/initiatives"
    fi

    ABBIA_MEMORY_DIR="$ABBIA_DIR/memory"
    ABBIA_METRICS_DIR="$ABBIA_DIR/metrics"
    ABBIA_ARCHIVE_DIR="$ABBIA_DIR/archive"
    ABBIA_SESSIONS_DIR="$ABBIA_DIR/sessions"

    # Alias de compatibilidad para Stratum y AI-Agents
    STRATUM_DIR="$ABBIA_DIR"
    STRATUM_IS_LEGACY="$ABBIA_IS_LEGACY"
    STRATUM_CORE="$ABBIA_CORE"
    STRATUM_INITIATIVES_DIR="$ABBIA_INITIATIVES_DIR"
    STRATUM_MEMORY_DIR="$ABBIA_MEMORY_DIR"
    STRATUM_METRICS_DIR="$ABBIA_METRICS_DIR"
    STRATUM_ARCHIVE_DIR="$ABBIA_ARCHIVE_DIR"
    STRATUM_SESSIONS_DIR="$ABBIA_SESSIONS_DIR"

    AI_DIR="$ABBIA_DIR"
    FEATURES_DIR="$ABBIA_INITIATIVES_DIR"
    ARCHIVE_DIR="$ABBIA_ARCHIVE_DIR"
    MEM_DIR="$ABBIA_MEMORY_DIR"
    METRICS_DIR="$ABBIA_METRICS_DIR"
}

# Alias funcional retrocompatible
resolve_stratum_paths() {
    resolve_abbia_paths "$@"
}

# Inicializar resolución de rutas por defecto
resolve_abbia_paths "$CWD"

# ---------- Iniciativas: tipos y patrón de nomenclatura ----------
# Tipos de iniciativa soportados en .abbia/initiatives/ y .abbia/archive/.
# - FEAT: feature | BUG: corrección | AUDIT: auditoría/seguridad | REF: refactor
INITIATIVE_TYPES="FEAT BUG AUDIT REF"

# Patrón central de nomenclatura: <TIPO>-<ID 3 dígitos>-<slug>
initiative_name_pattern() {
    printf '^(%s)-[0-9]{3}-[a-z0-9-]+$' "$(echo "$INITIATIVE_TYPES" | tr ' ' '|')"
}

# Devuelve los archivos obligatorios de inicio para un tipo.
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

# Roles del pipeline de Abbia OS
AGENT_ROLES="analyst ui-designer architect developer qa tech-lead devops skill-manager"

# Re-genera .abbia/memory/context-snapshot.md compactando workflow-log + knowledge-graph + patterns.
# Uso: regenerate_context_snapshot <PROJECT_ROOT>
regenerate_context_snapshot() {
    local project_root="${1:-$(detect_project_root)}"
    resolve_abbia_paths "$project_root"

    local mem_dir="$ABBIA_MEMORY_DIR"
    local log="$mem_dir/workflow-log.md"
    local kg_file="$ABBIA_DIR/knowledge-graph.yaml"
    local dec_file="$ABBIA_DIR/decisions.md"
    local patterns="$mem_dir/patterns-learned.md"
    local out="$mem_dir/context-snapshot.md"

    mkdir -p "$mem_dir"

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

    # --- Patrones aprendidos ---
    local pats=""
    if [ -f "$patterns" ]; then
        pats=$(grep -E '^## ' "$patterns" | grep -v '^## Problema:' | tail -5 || true)
    fi
    if [ -z "$pats" ]; then
        pats="(sin patrones aún en patterns-learned.md)"
    fi

    cat > "$out" << EOF
# Context Snapshot — Abbia 3-Tier Memory

> Generado automáticamente por finish-phase.sh al culminar una fase en Abbia OS.
> Compacta \`workflow-log.md\` + \`knowledge-graph.yaml\` + \`patterns-learned.md\` —
> **no se edita a mano**. Máximo ~30-50 líneas.

## Estado del proyecto (Últimas fases cerradas)

$recent

## Decisiones vigentes (Knowledge Graph)

$decisions

## Patrones relevantes (Procedural Memory)

$pats

EOF

    # --- Resumen de telemetría ---
    local metrics_file="$ABBIA_METRICS_DIR/executions.yaml"
    if [ -f "$metrics_file" ]; then
        local total_sessions=0
        local null_tokens=0
        local measured_sessions=0
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
## Métricas de telemetría (Abbia Observability)

- Total sesiones registradas: **$total_sessions**
- Con tokens medidos: **$measured_sessions** | Sin tokens (null): **$null_tokens**
$warn_line

Referencia: docs/agent-metrics.md (Abbia OS $ABBIA_VERSION).
EOF
    else
        cat >> "$out" << EOF
## Métricas de telemetría (Abbia Observability)

> Sin datos en $ABBIA_METRICS_DIR/executions.yaml aún.

Referencia: docs/agent-metrics.md (Abbia OS $ABBIA_VERSION).
EOF
    fi
}
