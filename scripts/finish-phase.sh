#!/usr/bin/env bash

# ==============================================================================
# finish-phase.sh — ai-agents Phase Closer (registro de memoria, métricas y KG)
# ==============================================================================
# Cierra una fase del pipeline registrando de forma automática:
#   1. Entrada en .ai/memory/workflow-log.md (append-only)
#   2. Ejecución en .ai/metrics/executions.yaml (append-only)
#   3. Regeneración de .ai/memory/context-snapshot.md (compacía)
# Esto garantiza que memory, metrics y snapshot tengan datos sin depender de
# que cada agente recuerde registrarse al terminar su fase.
#
# Uso:
#   bash finish-phase.sh <INICIATIVA> <FASE> [ROL] [OPCIONES]
#   Ej:  bash finish-phase.sh FEAT-114 qa qa --mode estandar
#        bash finish-phase.sh FEAT-114 architecture              # ROL auto-sugerido
#        bash finish-phase.sh BUG-022 implement developer --tokens-in 5000 --note "Fix race condition"
#
# Fases típicas: analysis, ui-design, architecture, tech-review-1, implement,
# qa, tech-review-2, approval, deploy. (ver docs/workflow-dag.md)
#
# Opciones:
#   --mode rapido|estandar|profundo   Modo del DAG (default: estandar)
#   --tokens-in N   Tokens de entrada (default: null)
#   --tokens-out N  Tokens de salida (default: null)
#   --duration N    Duración en segundos (default: null)
#   --attempts N    Intentos del nodo incl. back-edges (default: 1)
#   --verdict V     PASS|FAIL|APROBADO|RECHAZADO (solo si la fase es un gate)
#   --source S      measured|estimate (default: estimate)
#   --note "..."    Decisión/resumen breve para workflow-log
#   --archive       Archiva automáticamente la iniciativa en .ai/archive/ tras cerrar la fase
#   --ask-archive   Pregunta interactivamente si archivar la iniciativa tras cerrar la fase
#   --no-snapshot   No regenerar context-snapshot (útil en procesos por lotes)
# ==============================================================================

set -euo pipefail

# Determinar directorio del script e importar utilidades comunes
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo "Error: No se encontró common.sh en $SCRIPT_DIR"
    exit 1
fi

PROJECT_ROOT="$(detect_project_root)"

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🏁 Cierre de Fase (ai-agents OS)               ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Proyecto detectado: ${YELLOW}$PROJECT_ROOT${NC}"

# ---------- 1. Parsear argumentos ----------
INITIATIVE="${1:-}"
PHASE="${2:-}"
# El 3er argumento es ROL solo si no empieza con "--" (puede ser el primer flag)
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
NOTE=""
ARCHIVE=false
ASK_ARCHIVE=false
NO_SNAPSHOT=false

# Flags (a partir del 4º argumento o desde el 3º si no hay rol explícito)
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
        --source)     SOURCE="${ARGS[$((i+1))]:-estimate}"; i=$((i+2)) ;;
        --note)       NOTE="${ARGS[$((i+1))]:-}"; i=$((i+2)) ;;
        --archive)    ARCHIVE=true; i=$((i+1)) ;;
        --ask-archive) ASK_ARCHIVE=true; i=$((i+1)) ;;
        --no-snapshot) NO_SNAPSHOT=true; i=$((i+1)) ;;
        --) i=$((i+1)) ;;
        -*) echo -e "${RED}Error: Opción desconocida '${ARGS[$i]}'.${NC}"; exit 1 ;;
        *) i=$((i+1)) ;;
    esac
done

# ---------- 2. Validaciones & Auto-detección ----------
if [ -z "$INITIATIVE" ] || [ -z "$PHASE" ]; then
    echo -e "${RED}Error: Se requieren al menos <INICIATIVA> y <FASE>.${NC}"
    echo -e "Uso: bash finish-phase.sh <INICIATIVA> <FASE> [ROL] [OPCIONES]"
    echo -e "  ej: bash finish-phase.sh FEAT-114 qa"
    exit 1
fi

# Aceptar tanto FEAT-NNN como FEAT-NNN-slug (full name)
INI_PATTERN_FULL="$(initiative_name_pattern)"
INI_PATTERN_ID="$(initiative_id_pattern)"
if [[ "$INITIATIVE" =~ $INI_PATTERN_FULL ]]; then
    # Extraer solo TIPO-NNN para registrar en metrics (normalizar)
    INITIATIVE_ID=$(echo "$INITIATIVE" | grep -oE "^($(echo "$INITIATIVE_TYPES" | tr ' ' '|'))-[0-9]{3}")
    echo -e "${GREEN}✓ Iniciativa con slug detectada: $INITIATIVE → ID canónico: $INITIATIVE_ID${NC}"
elif [[ "$INITIATIVE" =~ $INI_PATTERN_ID ]]; then
    INITIATIVE_ID="$INITIATIVE"
else
    echo -e "${RED}Error: INICIATIVA debe ser '<$(initiative_types_readable)>-<NNN>' o '<$(initiative_types_readable)>-<NNN>-<slug>' (ej: FEAT-114, BUG-022-mi-bug).${NC}"
    exit 1
fi

# Advertir si la fase no coincide con los nombres canónicos del DAG
CANONICAL_PHASES="analysis discovery ui-design architecture tech-review-1 tech-review-2 implement tasks qa approval deploy"
PHASE_LOWER=$(echo "$PHASE" | tr '[:upper:]' '[:lower:]')
if [[ ! " $CANONICAL_PHASES " =~ " $PHASE_LOWER " ]]; then
    echo -e "${YELLOW}⚠ Fase '$PHASE' no es un nombre canónico del DAG. Nombres válidos: $CANONICAL_PHASES${NC}"
    echo -e "${YELLOW}  Usando '$PHASE' tal cual — considera usar el nombre canónico para consistencia.${NC}"
fi

# Auto-inferir target_env si no se especificó
if [ "$TARGET_ENV" = "null" ] || [ -z "$TARGET_ENV" ]; then
    case "$PHASE_LOWER" in
        analysis|discovery|ui-design|architecture|tech-review-1|implement|tasks)
            TARGET_ENV="local" ;;
        qa|tech-review-2)
            TARGET_ENV="staging" ;;
        approval|deploy)
            TARGET_ENV="production" ;;
        *)
            TARGET_ENV="local" ;;
    esac
fi

# Auto-detectar provider si no se especificó
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

# Auto-detectar rama de Git
GIT_BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "null")
[ -z "$GIT_BRANCH" ] && GIT_BRANCH="null"

# Sugerir ROL según fase si no se pasó
if [ -z "$ROLE" ]; then
    case "$PHASE_LOWER" in
        analysis|discovery)  ROLE="analyst" ;;
        ui-design)           ROLE="ui-designer" ;;
        architecture|tech-review-1) ROLE="architect" ;;
        implement|tasks)     ROLE="developer" ;;
        qa|tech-review-2)    ROLE="qa" ;;
        approval)            ROLE="tech-lead" ;;
        deploy)              ROLE="devops" ;;
        *) echo -e "${YELLOW}! No pude inferir el rol para la fase '$PHASE'; indícalo (ej: analyst|architect|developer|qa|tech-lead|devops).${NC}"; exit 1 ;;
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

# Advertir si tokens no se pasaron (promover telemetría real)
if [ "$TOKENS_IN" = "null" ] && [ "$TOKENS_OUT" = "null" ]; then
    echo -e "${YELLOW}⚠ Sin telemetría de tokens (quedarán como null). Para registrar tokens reales, usá:${NC}"
    echo -e "${YELLOW}  --tokens-in <N> --tokens-out <N> --duration <segundos> --source measured${NC}"
    echo -e "${YELLOW}  (El valor lo encontrás en el contador de tokens de tu IDE/CLI de IA)${NC}"
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ---------- 3. Registrar entrada en workflow-log.md (append-only) ----------
MEM_DIR="$PROJECT_ROOT/.ai/memory"
LOG_FILE="$MEM_DIR/workflow-log.md"
mkdir -p "$MEM_DIR"

if [ -z "$NOTE" ]; then
    NOTE="Cierre de fase $PHASE. Documentación de la fase generada en .ai/features/$INITIATIVE/."
fi

cat >> "$LOG_FILE" << EOF

## [$INITIATIVE_ID] — $ROLE ($TS)

- **Fase cerrada:** $PHASE
- **Decisión:** $NOTE
- **Razón:** La fase produjo/validó el artefacto correspondiente del DAG (ver docs/workflow-dag.md).
- **Alternativas descartadas:** —
- **Riesgo detectado:** ninguno
- **Outputs producidos:** .ai/features/$INITIATIVE/
EOF
echo -e "${GREEN}✓ Entrada agregada a workflow-log.md (append-only).${NC}"

# ---------- 4. Registrar ejecución en metrics/executions.yaml (append-only) ----------
METRICS_DIR="$PROJECT_ROOT/.ai/metrics"
METRICS_FILE="$METRICS_DIR/executions.yaml"
mkdir -p "$METRICS_DIR"

if [ ! -f "$METRICS_FILE" ]; then
    cat > "$METRICS_FILE" << 'EOF'
# ==============================================================================
# executions.yaml — Registro de Métricas por Ejecución de Agente
# ==============================================================================
# Append-only: cada ejecución de un agente agrega una entrada; nunca se reescribe.
# Documentación: docs/agent-metrics.md (framework ai-agents).
# ==============================================================================

executions:
EOF
else
    # Si el archivo es el template aún (tiene la entrada de ejemplo con ts: YYYY),
    # descartar esa entrada de ejemplo para que los append sean reales.
    if grep -qE '^[[:space:]]*- ts: YYYY-MM-DDTHH:MM:SSZ' "$METRICS_FILE"; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/^[[:space:]]*- ts: YYYY-MM-DDTHH:MM:SSZ/,$d' "$METRICS_FILE"
        else
            sed -i '/^[[:space:]]*- ts: YYYY-MM-DDTHH:MM:SSZ/,$d' "$METRICS_FILE"
        fi
        printf '\n' >> "$METRICS_FILE"
        echo -e "${YELLOW}! Template actualizado: entrada de ejemplo eliminada de executions.yaml${NC}"
    fi
    # Garantizar salto de línea antes del append
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

# ---------- 4b. Regenerar aggregates.yaml ----------
AGGREGATES_FILE="$METRICS_DIR/aggregates.yaml"
generate_aggregates() {
    local execfile="$1"
    local outfile="$2"
    [ ! -f "$execfile" ] && return

    # Usar python3 si está disponible para parsear YAML limpiamente
    if command -v python3 &>/dev/null; then
        python3 - "$execfile" "$outfile" << 'PYEOF'
import sys, re
from collections import defaultdict
from datetime import datetime, timezone

execfile = sys.argv[1]
outfile  = sys.argv[2]

# Mini-parser YAML de executions (no requiere pyyaml)
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
    '# ==============================================================================',
    '# aggregates.yaml — Métricas Agregadas por Fase / Rol / Modelo / Entorno / Iniciativa',
    '# ==============================================================================',
    '# Generado automáticamente por finish-phase.sh — NO editar a mano.',
    '# Fuente: .ai/metrics/executions.yaml  |  Docs: docs/agent-metrics.md',
    '# ==============================================================================',
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
    lines.append(f'    null_tokens: {v["null_tokens"]}  # ejecuciones sin telemetría real')

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
print(f"aggregates.yaml generado: {len(entries)} ejecuciones, {len(per_phase)} fases, {len(per_role)} roles, {len(per_model)} modelos, {len(per_env)} entornos, {len(per_feature)} iniciativas.")
PYEOF
        echo -e "${GREEN}✓ aggregates.yaml regenerado.${NC}"
    else
        echo -e "${YELLOW}! python3 no disponible — aggregates.yaml no se regeneró (opcional).${NC}"
    fi
}
generate_aggregates "$METRICS_FILE" "$AGGREGATES_FILE"

# ---------- 5. Regenerar context-snapshot ----------
if [ "${NO_SNAPSHOT:-false}" != "true" ]; then
    regenerate_context_snapshot "$PROJECT_ROOT"
    echo -e "${GREEN}✓ context-snapshot.md regenerado.${NC}"
fi

# ---------- 6. Archivado Automático / Interactivo (si aplica) ----------
if [ "$ARCHIVE" = true ]; then
    echo -e "\n${BLUE}➔ Ejecutando archivado automático...${NC}"
    bash "$SCRIPT_DIR/archive-initiative.sh" "$INITIATIVE" ${NOTE:+--note "$NOTE"}
elif [ "$ASK_ARCHIVE" = true ]; then
    echo -e "\n${YELLOW}➔ Solicitando confirmación de archivado...${NC}"
    bash "$SCRIPT_DIR/archive-initiative.sh" "$INITIATIVE" --prompt ${NOTE:+--note "$NOTE"}
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   🎉 Fase '$PHASE' cerrada para $INITIATIVE ($ROLE)${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Timestamp: ${YELLOW}$TS${NC}"
if [ "$TOKENS_IN" = "null" ] || [ "$TOKENS_OUT" = "null" ]; then
    echo -e "${YELLOW}⚠  Tokens sin registrar. Para la próxima fase, agregá al comando:${NC}"
    echo -e "${YELLOW}   --tokens-in <N> --tokens-out <N> --source measured${NC}"
fi
echo -e "Siguiente: registra las decisiones arquitectónicas en .ai/decisions.md"
echo -e "y actualiza .ai/knowledge-graph.yaml (nodo ARCH-NNN) si aplica."
echo -e "====================================================="