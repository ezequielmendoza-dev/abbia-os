#!/usr/bin/env bash

# ==============================================================================
# finish-phase.sh — Abbia OS Phase Closer (registro de memoria, métricas y KG)
# ==============================================================================
# Cierra una fase del pipeline registrando de forma automática:
#   1. Entrada en .abbia/memory/workflow-log.md (append-only)
#   2. Ejecución en .abbia/metrics/executions.yaml (append-only)
#   3. Regeneración de .abbia/metrics/aggregates.yaml
#   4. Regeneración de .abbia/memory/context-snapshot.md (compactado)
#
# Uso:
#   bash finish-phase.sh <INICIATIVA> <FASE> [ROL] [OPCIONES]
#   Ej:  bash finish-phase.sh FEAT-114 qa qa --mode estandar
#        bash finish-phase.sh FEAT-114 architecture              # ROL auto-sugerido
#        bash finish-phase.sh BUG-022 implement developer --tokens-in 5000 --note "Fix race condition"
#        ./abbia finish FEAT-114 qa qa --tokens-in 5000 --tokens-out 1200 --duration 45 --source measured
#
# Opciones:
#   --mode rapido|estandar|profundo   Modo del DAG (default: estandar)
#   --model M                         Modelo utilizado (ej: claude-3-7-sonnet)
#   --provider P                      Proveedor (ej: cursor, claude-code, antigravity)
#   --tokens-in N                     Tokens de entrada (default: auto-estimado o null si --no-estimate)
#   --tokens-out N                    Tokens de salida (default: auto-estimado o null si --no-estimate)
#   --duration N                      Duración en segundos (default: auto-estimado o null si --no-estimate)
#   --attempts N                      Intentos del nodo incl. back-edges (default: 1)
#   --verdict V                       PASS|FAIL|APROBADO|RECHAZADO (si la fase es un gate)
#   --source S                        measured|estimate (default: estimate)
#   --note "..."                      Decisión/resumen breve para workflow-log
#   --archive                         Archiva automáticamente la iniciativa en archive/
#   --ask-archive                     Pregunta interactivamente si archivar
#   --no-snapshot                     No regenerar context-snapshot
#   --no-estimate                     No auto-estimar tokens si no se especifican (dejar como null)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo "Error: No se encontró common.sh en $SCRIPT_DIR"
    exit 1
fi

PROJECT_ROOT="$(detect_project_root)"
resolve_abbia_paths "$PROJECT_ROOT"

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}     🏁 Cierre de Fase (Abbia OS v4.0.0)            ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Proyecto detectado: ${YELLOW}$PROJECT_ROOT${NC}"

INITIATIVE="${1:-}"
PHASE="${2:-}"
if [ $# -ge 3 ] && [[ "${3:-}" != -* ]]; then
    ROLE="${3:-}"
else
    ROLE=""
fi

MODE="estandar"
MODEL="null"
PROVIDER="null"
TARGET_ENV="null"
TOKENS_IN="null"
TOKENS_OUT="null"
DURATION_S="null"
ATTEMPTS=1
VERDICT="null"
SOURCE="estimate"
SOURCE_EXPLICIT=false
NOTE=""
ARCHIVE=false
ASK_ARCHIVE=false
NO_SNAPSHOT=false
NO_ESTIMATE=false
ESTIMATED_TELEMETRY=false

ARGS=("$@")
i=0
while [ $i -lt ${#ARGS[@]} ]; do
    case "${ARGS[$i]}" in
        --mode)       MODE="${ARGS[$((i+1))]:-estandar}"; i=$((i+2)) ;;
        --model)      MODEL="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --provider)   PROVIDER="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --env|--target-env) TARGET_ENV="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --tokens-in)  TOKENS_IN="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --tokens-out) TOKENS_OUT="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --duration)   DURATION_S="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --attempts)   ATTEMPTS="${ARGS[$((i+1))]:-1}"; i=$((i+2)) ;;
        --verdict)    VERDICT="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --source)     SOURCE="${ARGS[$((i+1))]:-estimate}"; SOURCE_EXPLICIT=true; i=$((i+2)) ;;
        --note)       NOTE="${ARGS[$((i+1))]:-}"; i=$((i+2)) ;;
        --archive)    ARCHIVE=true; i=$((i+1)) ;;
        --ask-archive) ASK_ARCHIVE=true; i=$((i+1)) ;;
        --no-snapshot) NO_SNAPSHOT=true; i=$((i+1)) ;;
        --no-estimate) NO_ESTIMATE=true; i=$((i+1)) ;;
        --) i=$((i+1)) ;;
        -*) echo -e "${RED}Error: Opción desconocida '${ARGS[$i]}'.${NC}"; exit 1 ;;
        *) i=$((i+1)) ;;
    esac
done

if [ -z "$INITIATIVE" ] || [ -z "$PHASE" ]; then
    echo -e "${RED}Error: Se requieren al menos <INICIATIVA> y <FASE>.${NC}"
    echo -e "Uso: bash finish-phase.sh <INICIATIVA> <FASE> [ROL] [OPCIONES]"
    echo -e "  ej: bash finish-phase.sh FEAT-114 qa"
    exit 1
fi

INI_PATTERN_FULL="$(initiative_name_pattern)"
INI_PATTERN_ID="$(initiative_id_pattern)"
if [[ "$INITIATIVE" =~ $INI_PATTERN_FULL ]]; then
    INITIATIVE_ID=$(echo "$INITIATIVE" | grep -oE "^($(echo "$INITIATIVE_TYPES" | tr ' ' '|'))-[0-9]{3}")
    echo -e "${GREEN}✓ Iniciativa detectada: $INITIATIVE → ID canónico: $INITIATIVE_ID${NC}"
elif [[ "$INITIATIVE" =~ $INI_PATTERN_ID ]]; then
    INITIATIVE_ID="$INITIATIVE"
else
    echo -e "${RED}Error: INICIATIVA debe ser '<$(initiative_types_readable)>-<NNN>' o '<$(initiative_types_readable)>-<NNN>-<slug>' (ej: FEAT-114, BUG-022-mi-bug).${NC}"
    exit 1
fi

CANONICAL_PHASES="analysis discovery ui-design architecture tech-review-1 tech-review-2 implement tasks qa approval deploy"
PHASE_LOWER=$(echo "$PHASE" | tr '[:upper:]' '[:lower:]')
if [[ ! " $CANONICAL_PHASES " =~ " $PHASE_LOWER " ]]; then
    echo -e "${YELLOW}⚠ Fase '$PHASE' no es un nombre canónico del DAG. Nombres válidos: $CANONICAL_PHASES${NC}"
fi

if [ "$TARGET_ENV" = "null" ] || [ -z "$TARGET_ENV" ]; then
    case "$PHASE_LOWER" in
        analysis|discovery|ui-design|architecture|tech-review-1|implement|tasks) TARGET_ENV="local" ;;
        qa|tech-review-2) TARGET_ENV="staging" ;;
        approval|deploy) TARGET_ENV="production" ;;
        *) TARGET_ENV="local" ;;
    esac
fi

# Auto-descubrimiento de variables de entorno y sesión
discover_session_telemetry

if [ "$PROVIDER" = "null" ] || [ -z "$PROVIDER" ]; then
    if [ -n "${OPENCODE_SERVER:-}" ] || [ -n "${OPENCODE:-}" ]; then
        PROVIDER="opencode"
    elif [ -n "${ANTIGRAVITY_AGENT:-}" ] || [ -n "${GEMINI_CLI:-}" ]; then
        PROVIDER="antigravity"
    elif [ -n "${CURSOR_TRACE_ID:-}" ] || [ -n "${CURSOR_EXECPATH:-}" ]; then
        PROVIDER="cursor"
    elif [ -n "${CLAUDE_CODE:-}" ]; then
        PROVIDER="claude-code"
    elif [ -n "${WINDSURF_PORT:-}" ]; then
        PROVIDER="windsurf"
    fi
fi

GIT_BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "null")
[ -z "$GIT_BRANCH" ] && GIT_BRANCH="null"

if [ -z "$ROLE" ]; then
    case "$PHASE_LOWER" in
        analysis|discovery)  ROLE="analyst" ;;
        ui-design)           ROLE="ui-designer" ;;
        architecture|tech-review-1) ROLE="architect" ;;
        implement|tasks)     ROLE="developer" ;;
        qa|tech-review-2)    ROLE="qa" ;;
        approval)            ROLE="tech-lead" ;;
        deploy)              ROLE="devops" ;;
        *) echo -e "${YELLOW}! No pude inferir el rol para la fase '$PHASE'; indícalo.${NC}"; exit 1 ;;
    esac
    echo -e "${GREEN}✓ Rol sugerido para fase '$PHASE': $ROLE${NC}"
fi

if [[ ! " $AGENT_ROLES " =~ " $ROLE " ]]; then
    echo -e "${RED}Error: ROL debe ser uno de: $AGENT_ROLES${NC}"
    exit 1
fi

case "$MODE" in rapido|estandar|profundo) : ;; *) echo -e "${RED}Error: --mode debe ser rapido|estandar|profundo.${NC}"; exit 1 ;; esac
case "$SOURCE" in measured|estimate) : ;; *) echo -e "${RED}Error: --source debe ser measured|estimate.${NC}"; exit 1 ;; esac
if [ "$VERDICT" != "null" ] && [[ ! "$VERDICT" =~ ^(PASS|FAIL|APROBADO|RECHAZADO)$ ]]; then
    echo -e "${RED}Error: --verdict debe ser PASS|FAIL|APROBADO|RECHAZADO.${NC}"; exit 1
fi

# Auto-estimación heurística si no se pasaron tokens y no está deshabilitada
if [ "$NO_ESTIMATE" = false ]; then
    estimate_phase_consumption "$PROJECT_ROOT" "$INITIATIVE_ID" "$PHASE" "$ROLE"
fi

if [ "$ESTIMATED_TELEMETRY" = true ]; then
    [ "$SOURCE_EXPLICIT" = false ] && SOURCE="estimate"
    echo -e "${CYAN}ℹ Telemetría estimada automáticamente (heurística de contexto/artefactos): in=${TOKENS_IN}, out=${TOKENS_OUT}, duration=${DURATION_S}s (source: ${SOURCE}).${NC}"
elif [ "$TOKENS_IN" = "null" ] && [ "$TOKENS_OUT" = "null" ]; then
    echo -e "${YELLOW}⚠ Sin telemetría de tokens (quedarán como null). Para registrar tokens reales, usa:${NC}"
    echo -e "${YELLOW}  --tokens-in <N> --tokens-out <N> --duration <segundos> --source measured${NC}"
else
    echo -e "${GREEN}✓ Telemetría registrada: in=${TOKENS_IN}, out=${TOKENS_OUT}, duration=${DURATION_S}s (source: ${SOURCE}).${NC}"
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. workflow-log.md (append-only)
LOG_FILE="$ABBIA_MEMORY_DIR/workflow-log.md"
mkdir -p "$ABBIA_MEMORY_DIR"

if [ -z "$NOTE" ]; then
    NOTE="Cierre de fase $PHASE en Abbia OS. Documentación generada en ${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}/$INITIATIVE/."
fi

cat >> "$LOG_FILE" << EOF

## [$INITIATIVE_ID] — $ROLE ($TS)

- **Fase cerrada:** $PHASE
- **Decisión:** $NOTE
- **Razón:** La fase produjo/validó el artefacto correspondiente del DAG de Abbia OS.
- **Alternativas descartadas:** —
- **Riesgo detectado:** ninguno
- **Outputs producidos:** ${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}/$INITIATIVE/
EOF
echo -e "${GREEN}✓ Entrada agregada a workflow-log.md (append-only).${NC}"

# 2. executions.yaml (append-only)
METRICS_FILE="$ABBIA_METRICS_DIR/executions.yaml"
mkdir -p "$ABBIA_METRICS_DIR"

if [ ! -f "$METRICS_FILE" ]; then
    cat > "$METRICS_FILE" << 'EOF'
# ==============================================================================
# executions.yaml — Abbia Observability & Telemetry
# ==============================================================================
# Append-only: cada ejecución de un agente agrega una entrada; nunca se reescribe.
# ==============================================================================

executions:
EOF
else
    if grep -qE '^[[:space:]]*- ts: YYYY-MM-DDTHH:MM:SSZ' "$METRICS_FILE"; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/^[[:space:]]*- ts: YYYY-MM-DDTHH:MM:SSZ/,$d' "$METRICS_FILE"
        else
            sed -i '/^[[:space:]]*- ts: YYYY-MM-DDTHH:MM:SSZ/,$d' "$METRICS_FILE"
        fi
        printf '\n' >> "$METRICS_FILE"
    fi
    LASTBYTE=$(tail -c 1 "$METRICS_FILE" | od -An -tx1 | tr -d ' \n')
    if [ "$LASTBYTE" != "0a" ]; then
        printf '\n' >> "$METRICS_FILE"
    fi
fi

cat >> "$METRICS_FILE" << EOF
  - ts: $TS
    initiative: $INITIATIVE_ID
    role: $ROLE
    phase: $PHASE
    mode: $MODE
    model: $MODEL
    provider: $PROVIDER
    target_env: $TARGET_ENV
    git_branch: $GIT_BRANCH
    tokens_in: $TOKENS_IN
    tokens_out: $TOKENS_OUT
    duration_s: $DURATION_S
    attempts: $ATTEMPTS
    verdict: $VERDICT
    source: $SOURCE
EOF
echo -e "${GREEN}✓ Ejecución registrada en executions.yaml.${NC}"

# 3. Regenerar aggregates.yaml
AGGREGATES_FILE="$ABBIA_METRICS_DIR/aggregates.yaml"
generate_aggregates() {
    local execfile="$1"
    local outfile="$2"
    [ ! -f "$execfile" ] && return

    if command -v python3 &>/dev/null; then
        python3 - "$execfile" "$outfile" << 'PYEOF'
import sys, re
from collections import defaultdict
from datetime import datetime, timezone

execfile = sys.argv[1]
outfile  = sys.argv[2]

entries = []
current = {}
with open(execfile) as f:
    for line in f:
        line = line.rstrip()
        m = re.match(r'^\s+- ts:\s*(.+)$', line)
        if m:
            if current:
                entries.append(current)
            current = {'ts': m.group(1).strip()}
            continue
        for key in ['initiative','role','phase','mode','model','provider','target_env','git_branch','tokens_in','tokens_out','duration_s','attempts','verdict','source']:
            m = re.match(rf'^\s+{key}:\s*(.+)$', line)
            if m:
                val = m.group(1).strip()
                current[key] = None if val == 'null' else val
    if current:
        entries.append(current)

def safe_int(v, default=0):
    try: return int(v) if v is not None else default
    except: return default

per_phase    = defaultdict(lambda: {'tokens_total': 0, 'duration_s': 0, 'sample': 0, 'null_tokens': 0})
per_role     = defaultdict(lambda: {'tokens_total': 0, 'duration_s': 0, 'attempts_total': 0, 'sample': 0, 'null_tokens': 0})
per_feature  = defaultdict(lambda: {'tokens_total': 0, 'duration_s': 0, 'count': 0, 'retries': 0, 'null_tokens': 0})
per_model    = defaultdict(lambda: {'tokens_total': 0, 'tokens_in': 0, 'tokens_out': 0, 'sample': 0, 'null_tokens': 0})
per_provider = defaultdict(lambda: {'tokens_total': 0, 'sample': 0})
per_env      = defaultdict(lambda: {'tokens_total': 0, 'sample': 0})

for ex in entries:
    ti = safe_int(ex.get('tokens_in'))
    to = safe_int(ex.get('tokens_out'))
    tt = ti + to
    ds = safe_int(ex.get('duration_s'))
    at = safe_int(ex.get('attempts'), 1)
    phase    = ex.get('phase') or 'desconocida'
    role     = ex.get('role')  or 'desconocido'
    ini      = ex.get('initiative') or 'desconocida'
    model    = ex.get('model') or 'no-especificado'
    provider = ex.get('provider') or 'no-especificado'
    env      = ex.get('target_env') or 'local'
    null_tok = 1 if (ex.get('tokens_in') is None and ex.get('tokens_out') is None) else 0

    per_phase[phase]['tokens_total'] += tt
    per_phase[phase]['duration_s']   += ds
    per_phase[phase]['sample']       += 1
    per_phase[phase]['null_tokens']  += null_tok

    per_role[role]['tokens_total']    += tt
    per_role[role]['duration_s']      += ds
    per_role[role]['attempts_total']  += at
    per_role[role]['sample']          += 1
    per_role[role]['null_tokens']     += null_tok

    per_feature[ini]['tokens_total'] += tt
    per_feature[ini]['duration_s']   += ds
    per_feature[ini]['count']        += 1
    per_feature[ini]['retries']      += max(0, at - 1)
    per_feature[ini]['null_tokens']  += null_tok

    per_model[model]['tokens_total'] += tt
    per_model[model]['tokens_in']    += ti
    per_model[model]['tokens_out']   += to
    per_model[model]['sample']       += 1
    per_model[model]['null_tokens']  += null_tok

    per_provider[provider]['tokens_total'] += tt
    per_provider[provider]['sample']       += 1

    per_env[env]['tokens_total'] += tt
    per_env[env]['sample']       += 1

lines = [
    '# ============================================================================== ',
    '# aggregates.yaml — Abbia Observability Aggregated Metrics',
    '# ============================================================================== ',
    '# Generado automáticamente por finish-phase.sh — NO editar a mano.',
    '',
    f'generated_at: {datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}',
    f'total_executions: {len(entries)}',
    '',
    'per_phase:',
]
for k, v in sorted(per_phase.items()):
    lines.append(f'  {k}:')
    lines.append(f'    tokens_total: {v["tokens_total"]}')
    lines.append(f'    duration_s: {v["duration_s"]}')
    lines.append(f'    sample: {v["sample"]}')
    lines.append(f'    null_tokens: {v["null_tokens"]}')

lines += ['', 'per_role:']
for k, v in sorted(per_role.items()):
    lines.append(f'  {k}:')
    lines.append(f'    tokens_total: {v["tokens_total"]}')
    lines.append(f'    duration_s: {v["duration_s"]}')
    lines.append(f'    attempts_total: {v["attempts_total"]}')
    lines.append(f'    sample: {v["sample"]}')
    lines.append(f'    null_tokens: {v["null_tokens"]}')

lines += ['', 'per_model:']
for k, v in sorted(per_model.items()):
    lines.append(f'  {k}:')
    lines.append(f'    tokens_total: {v["tokens_total"]}')
    lines.append(f'    tokens_in: {v["tokens_in"]}')
    lines.append(f'    tokens_out: {v["tokens_out"]}')
    lines.append(f'    sample: {v["sample"]}')
    lines.append(f'    null_tokens: {v["null_tokens"]}')

lines += ['', 'per_provider:']
for k, v in sorted(per_provider.items()):
    lines.append(f'  {k}:')
    lines.append(f'    tokens_total: {v["tokens_total"]}')
    lines.append(f'    sample: {v["sample"]}')

lines += ['', 'per_env:']
for k, v in sorted(per_env.items()):
    lines.append(f'  {k}:')
    lines.append(f'    tokens_total: {v["tokens_total"]}')
    lines.append(f'    sample: {v["sample"]}')

lines += ['', 'per_feature:']
for k, v in sorted(per_feature.items()):
    rt = round(v["retries"] / v["count"], 2) if v["count"] > 0 else 0
    lines.append(f'  {k}:')
    lines.append(f'    tokens_total: {v["tokens_total"]}')
    lines.append(f'    duration_s: {v["duration_s"]}')
    lines.append(f'    count: {v["count"]}')
    lines.append(f'    retry_rate: {rt}')
    lines.append(f'    null_tokens: {v["null_tokens"]}')

with open(outfile, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')
print(f"aggregates.yaml generado: {len(entries)} ejecuciones.")
PYEOF
        echo -e "${GREEN}✓ aggregates.yaml regenerado.${NC}"
    fi
}
generate_aggregates "$METRICS_FILE" "$AGGREGATES_FILE"

# 4. Regenerar context-snapshot
if [ "${NO_SNAPSHOT:-false}" != "true" ]; then
    regenerate_context_snapshot "$PROJECT_ROOT"
    echo -e "${GREEN}✓ context-snapshot.md regenerado.${NC}"
fi

# 5. Archivado
if [ "$ARCHIVE" = true ]; then
    echo -e "\n${BLUE}➔ Ejecutando archivado automático...${NC}"
    bash "$SCRIPT_DIR/archive-initiative.sh" "$INITIATIVE" ${NOTE:+--note "$NOTE"}
elif [ "$ASK_ARCHIVE" = true ]; then
    echo -e "\n${YELLOW}➔ Solicitando confirmación de archivado...${NC}"
    bash "$SCRIPT_DIR/archive-initiative.sh" "$INITIATIVE" --prompt ${NOTE:+--note "$NOTE"}
fi

# 6. Auto-actualizar dashboard si existe
auto_refresh_dashboard_if_exists "$PROJECT_ROOT"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   🎉 Fase '$PHASE' cerrada para $INITIATIVE ($ROLE)${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Timestamp: ${YELLOW}$TS${NC}"
echo -e "====================================================="