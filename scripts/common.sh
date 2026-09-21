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

# Auto-descubrimiento de telemetría desde variables de entorno y metadatos de sesión
discover_session_telemetry() {
    # Variables de entorno prioritarias (inyectadas por runners, harnesses o scripts)
    if [ -n "${ABBIA_MODEL:-}" ] && [ "${MODEL:-null}" = "null" ]; then
        MODEL="$ABBIA_MODEL"
    fi
    if [ -n "${ABBIA_PROVIDER:-}" ] && [ "${PROVIDER:-null}" = "null" ]; then
        PROVIDER="$ABBIA_PROVIDER"
    fi
    if [ -n "${ABBIA_TOKENS_IN:-}" ] && [ "${TOKENS_IN:-null}" = "null" ]; then
        TOKENS_IN="$ABBIA_TOKENS_IN"
        SOURCE="measured"
    fi
    if [ -n "${ABBIA_TOKENS_OUT:-}" ] && [ "${TOKENS_OUT:-null}" = "null" ]; then
        TOKENS_OUT="$ABBIA_TOKENS_OUT"
        SOURCE="measured"
    fi
    if [ -n "${ABBIA_DURATION:-}" ] && [ "${DURATION_S:-null}" = "null" ]; then
        DURATION_S="$ABBIA_DURATION"
    fi
}

# Estimación heurística de consumo (tokens in/out y duración) basada en artefactos y contexto
estimate_phase_consumption() {
    local project_root="${1:-$(detect_project_root)}"
    local initiative="${2:-}"
    local phase="${3:-}"
    local role="${4:-}"
    resolve_abbia_paths "$project_root"

    # Si todos los campos ya tienen valor, nada que estimar
    if [ "${TOKENS_IN:-null}" != "null" ] && [ "${TOKENS_OUT:-null}" != "null" ] && [ "${DURATION_S:-null}" != "null" ]; then
        return 0
    fi

    if command -v python3 &>/dev/null; then
        local est_result
        est_result=$(python3 - "$project_root" "$initiative" "$phase" "$role" "$ABBIA_DIR" "$ABBIA_INITIATIVES_DIR" << 'PYEOF'
import sys, os, glob, re
from datetime import datetime, timezone

project_root = sys.argv[1]
initiative   = sys.argv[2]
phase        = sys.argv[3]
role         = sys.argv[4]
abbia_dir    = sys.argv[5]
ini_dir      = sys.argv[6]

# 1. Estimación de tokens de salida (artefactos generados/modificados)
out_bytes = 0
ini_matches = glob.glob(os.path.join(ini_dir, f"{initiative}*"))
if ini_matches and os.path.isdir(ini_matches[0]):
    for root, _, files in os.walk(ini_matches[0]):
        for f in files:
            fp = os.path.join(root, f)
            if os.path.isfile(fp):
                out_bytes += os.path.getsize(fp)

tokens_out = max(350, int(out_bytes / 3.8)) if out_bytes > 0 else 500

# 2. Estimación de tokens de entrada (contexto base + spec + rol)
in_bytes = 0
for f in ["context.md", "knowledge-graph.yaml", "memory/context-snapshot.md", "decisions.md"]:
    fp = os.path.join(abbia_dir, f)
    if os.path.isfile(fp):
        in_bytes += os.path.getsize(fp)

core_roles = os.path.join(abbia_dir, "core", "roles", f"{role}.md")
if not os.path.isfile(core_roles):
    core_roles = os.path.join(project_root, "roles", f"{role}.md")
if os.path.isfile(core_roles):
    in_bytes += os.path.getsize(core_roles)

if ini_matches and os.path.isdir(ini_matches[0]):
    for root, _, files in os.walk(ini_matches[0]):
        for f in files:
            fp = os.path.join(root, f)
            if os.path.isfile(fp):
                in_bytes += os.path.getsize(fp)

tokens_in = max(1800, int((in_bytes / 3.8) * 1.5))

# 3. Estimación de duración en segundos
duration_s = 180
exec_file = os.path.join(abbia_dir, "metrics", "executions.yaml")
if os.path.isfile(exec_file):
    last_ts = None
    with open(exec_file, "r", encoding="utf-8") as f:
        for line in f:
            m = re.match(r'^\s+- ts:\s*(.+)$', line)
            if m:
                last_ts = m.group(1).strip()
    if last_ts:
        try:
            dt_last = datetime.fromisoformat(last_ts.replace("Z", "+00:00"))
            dt_now = datetime.now(timezone.utc)
            delta = int((dt_now - dt_last).total_seconds())
            if 10 <= delta <= 3600:
                duration_s = delta
        except Exception:
            pass

if duration_s == 180:
    phase_durations = {
        "analysis": 240, "discovery": 240, "ui-design": 360,
        "architecture": 420, "tech-review-1": 180, "tech-review-2": 180,
        "implement": 600, "tasks": 300, "qa": 300, "approval": 120, "deploy": 180
    }
    duration_s = phase_durations.get(phase.lower(), 240)

print(f"{tokens_in}:{tokens_out}:{duration_s}")
PYEOF
        )
        if [ -n "$est_result" ]; then
            local est_ti est_to est_dur
            est_ti=$(echo "$est_result" | cut -d: -f1)
            est_to=$(echo "$est_result" | cut -d: -f2)
            est_dur=$(echo "$est_result" | cut -d: -f3)

            if [ "${TOKENS_IN:-null}" = "null" ]; then
                TOKENS_IN="$est_ti"
                ESTIMATED_TELEMETRY=true
            fi
            if [ "${TOKENS_OUT:-null}" = "null" ]; then
                TOKENS_OUT="$est_to"
                ESTIMATED_TELEMETRY=true
            fi
            if [ "${DURATION_S:-null}" = "null" ]; then
                DURATION_S="$est_dur"
            fi
        fi
    fi
}

# Re-genera .abbia/dashboard.html silenciosamente si ya existe en el proyecto destino
auto_refresh_dashboard_if_exists() {
    local project_root="${1:-$(detect_project_root)}"
    resolve_abbia_paths "$project_root"
    local dash_file="$ABBIA_DIR/dashboard.html"
    local dash_script=""

    if [ -f "$ABBIA_CORE/scripts/dashboard.sh" ]; then
        dash_script="$ABBIA_CORE/scripts/dashboard.sh"
    elif [ -f "$SCRIPT_DIR/dashboard.sh" ]; then
        dash_script="$SCRIPT_DIR/dashboard.sh"
    fi

    if [ -f "$dash_file" ] && [ -n "$dash_script" ]; then
        bash "$dash_script" --no-open >/dev/null 2>&1 || true
        echo -e "${GREEN}✓ Dashboard interactivo actualizado automáticamente (${dash_file#$PROJECT_ROOT/}).${NC}"
    fi
}



