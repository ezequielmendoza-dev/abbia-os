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
TOKENS_IN="null"
TOKENS_OUT="null"
DURATION_S="null"
ATTEMPTS=1
VERDICT="null"
SOURCE="estimate"
NOTE=""
NO_SNAPSHOT=false

# Flags (a partir del 4º argumento o desde el 3º si no hay rol explícito)
ARGS=("$@")
i=0
while [ $i -lt ${#ARGS[@]} ]; do
    case "${ARGS[$i]}" in
        --mode)       MODE="${ARGS[$((i+1))]:-estandar}"; i=$((i+2)) ;;
        --tokens-in)  TOKENS_IN="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --tokens-out) TOKENS_OUT="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --duration)   DURATION_S="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --attempts)   ATTEMPTS="${ARGS[$((i+1))]:-1}"; i=$((i+2)) ;;
        --verdict)    VERDICT="${ARGS[$((i+1))]:-null}"; i=$((i+2)) ;;
        --source)     SOURCE="${ARGS[$((i+1))]:-estimate}"; i=$((i+2)) ;;
        --note)       NOTE="${ARGS[$((i+1))]:-}"; i=$((i+2)) ;;
        --no-snapshot) NO_SNAPSHOT=true; i=$((i+1)) ;;
        --) i=$((i+1)) ;;
        -*) echo -e "${RED}Error: Opción desconocida '${ARGS[$i]}'.${NC}"; exit 1 ;;
        *) i=$((i+1)) ;;
    esac
done

# ---------- 2. Validaciones ----------
if [ -z "$INITIATIVE" ] || [ -z "$PHASE" ]; then
    echo -e "${RED}Error: Se requieren al menos <INICIATIVA> y <FASE>.${NC}"
    echo -e "Uso: bash finish-phase.sh <INICIATIVA> <FASE> [ROL] [OPCIONES]"
    echo -e "  ej: bash finish-phase.sh FEAT-114 qa"
    exit 1
fi

INI_PATTERN="$(initiative_id_pattern)"
if [[ ! "$INITIATIVE" =~ $INI_PATTERN ]]; then
    echo -e "${RED}Error: INICIATIVA debe ser '<$(initiative_types_readable)>-<NNN>' (ej: FEAT-114, BUG-022, AUDIT-003, REF-010).${NC}"
    exit 1
fi

# Sugerir ROL según fase si no se pasó
if [ -z "$ROLE" ]; then
    case "$PHASE" in
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

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ---------- 3. Registrar entrada en workflow-log.md (append-only) ----------
MEM_DIR="$PROJECT_ROOT/.ai/memory"
LOG_FILE="$MEM_DIR/workflow-log.md"
mkdir -p "$MEM_DIR"

if [ -z "$NOTE" ]; then
    NOTE="Cierre de fase $PHASE. Documentación de la fase generada en .ai/features/$INITIATIVE/."
fi

cat >> "$LOG_FILE" << EOF

## [$INITIATIVE] — $ROLE ($TS)

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
    initiative: $INITIATIVE
    role: $ROLE
    phase: $PHASE
    mode: $MODE
    tokens_in: $TOKENS_IN
    tokens_out: $TOKENS_OUT
    duration_s: $DURATION_S
    attempts: $ATTEMPTS
    verdict: $VERDICT
    source: $SOURCE
EOF
echo -e "${GREEN}✓ Ejecución registrada en executions.yaml.${NC}"

# ---------- 5. Regenerar context-snapshot ----------
if [ "${NO_SNAPSHOT:-false}" != "true" ]; then
    regenerate_context_snapshot "$PROJECT_ROOT"
    echo -e "${GREEN}✓ context-snapshot.md regenerado.${NC}"
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   🎉 Fase '$PHASE' cerrada para $INITIATIVE ($ROLE)${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Timestamp: ${YELLOW}$TS${NC}"
echo -e "Siguiente: registra las decisiones arquitectónicas en .ai/decisions.md"
echo -e "y actualiza .ai/knowledge-graph.yaml (nodo ARCH-NNN) si aplica."
echo -e "===================================================="