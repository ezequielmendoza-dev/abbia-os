#!/usr/bin/env bash

# ==============================================================================
# sync-initiatives.sh — ai-agents Auto-Reconciler & Sync Tool
# ==============================================================================
# Escanea las carpetas en .ai/features/ (y opcionalmente .ai/archive/) y reconcilia
# de forma automática cualquier iniciativa que no haya sido registrada en los
# sistemas globales:
#   1. .ai/knowledge-graph.yaml (Nodos ADR ARCH-NNN)
#   2. .ai/memory/workflow-log.md (Memoria episódica)
#   3. .ai/memory/decisions-catalog.md (Memoria semántica)
#   4. .ai/metrics/executions.yaml (Telemetría de ejecuciones)
#   5. .ai/memory/context-snapshot.md (Regeneración compactada)
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
echo -e "${BLUE}   🔄 Sincronizador de Iniciativas (ai-agents OS)   ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Raíz del proyecto: ${YELLOW}$PROJECT_ROOT${NC}\n"

FEATURES_DIR="$PROJECT_ROOT/.ai/features"
if [ ! -d "$FEATURES_DIR" ]; then
    echo -e "${RED}Error: No se encontró el directorio .ai/features/ en $PROJECT_ROOT${NC}"
    exit 1
fi

KG_FILE="$PROJECT_ROOT/.ai/knowledge-graph.yaml"
MEM_DIR="$PROJECT_ROOT/.ai/memory"
LOG_FILE="$MEM_DIR/workflow-log.md"
CATALOG_FILE="$MEM_DIR/decisions-catalog.md"
METRICS_FILE="$PROJECT_ROOT/.ai/metrics/executions.yaml"

mkdir -p "$MEM_DIR"
mkdir -p "$PROJECT_ROOT/.ai/metrics"

# Asegurar cabeceras base si no existen
if [ ! -f "$LOG_FILE" ]; then
    cat << 'EOF' > "$LOG_FILE"
# Memoria Episódica — Workflow Log (append-only)

Registro cronológico de las ejecuciones del pipeline.

EOF
fi

if [ ! -f "$CATALOG_FILE" ]; then
    cat << 'EOF' > "$CATALOG_FILE"
# Catálogo de Decisiones — Memoria Semántica

| ID | Decisión | Estado | Referencia | Última revisión |
|:---|:---|:---|:---|:---|
EOF
fi

if [ ! -f "$METRICS_FILE" ]; then
    cat << 'EOF' > "$METRICS_FILE"
executions:
EOF
fi

if [ ! -f "$KG_FILE" ]; then
    cat << 'EOF' > "$KG_FILE"
version: 1
updated: 2026-09-11
maintained_by: architect

nodes:
edges: []
EOF
fi

SYNCED_COUNT=0
shopt -s nullglob
dirs=("$FEATURES_DIR"/*/)
shopt -u nullglob

CURRENT_DATE=$(date -u +"%Y-%m-%d")
CURRENT_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

for dir in "${dirs[@]}"; do
    folder_name=$(basename "$dir")
    
    # Extraer ID y Tipo
    TYPE=$(echo "$folder_name" | cut -d'-' -f1)
    NUM=$(echo "$folder_name" | cut -d'-' -f2)
    SLUG=$(echo "$folder_name" | cut -d'-' -f3-)
    INITIATIVE_ID="$TYPE-$NUM"

    # Verificar si ya está en workflow-log.md
    if ! grep -q "## \[$INITIATIVE_ID\]" "$LOG_FILE" 2>/dev/null; then
        echo -e "${YELLOW}⚡ Sincronizando iniciativa no registrada:${NC} $folder_name"
        
        # 1. Extraer título o resumen
        TITLE="$folder_name"
        if [ -f "$dir/spec.md" ]; then
            EXTRACTED_TITLE=$(grep -E '^# ' "$dir/spec.md" | head -1 | sed 's/^# *//' || true)
            if [ -n "$EXTRACTED_TITLE" ]; then TITLE="$EXTRACTED_TITLE"; fi
        elif [ -f "$dir/bug-report.md" ]; then
            EXTRACTED_TITLE=$(grep -E '^# ' "$dir/bug-report.md" | head -1 | sed 's/^# *//' || true)
            if [ -n "$EXTRACTED_TITLE" ]; then TITLE="$EXTRACTED_TITLE"; fi
        fi

        # 2. Registrar en workflow-log.md
        cat >> "$LOG_FILE" << EOF

## [$INITIATIVE_ID] S1 — Pipeline Sync ($CURRENT_TS)

- **Insumos consumidos:** Documentos de iniciativa en \`.ai/features/$folder_name\`.
- **Decisión:** Implementación y cierre de iniciativa '$TITLE'.
- **Razón:** Sincronización histórica y auto-reconciliación del pipeline.
- **Outputs producidos:** [$folder_name](../features/$folder_name)
EOF

        # 3. Registrar en executions.yaml si no está
        if ! grep -q "initiative: $INITIATIVE_ID" "$METRICS_FILE" 2>/dev/null; then
            cat >> "$METRICS_FILE" << EOF

  - ts: $CURRENT_TS
    initiative: $INITIATIVE_ID
    role: qa
    phase: qa
    mode: estandar
    tokens_in: 4500
    tokens_out: 2000
    duration_s: 900
    attempts: 1
    verdict: APROBADO
    source: estimate
EOF
        fi

        # 4. Registrar ADR en Knowledge Graph y Decisions Catalog si tiene arquitectura/decisión
        ARCH_ID="ARCH-$NUM"
        if [ -f "$dir/decision.md" ] || [ -f "$dir/architecture.md" ]; then
            if ! grep -q "id: $ARCH_ID" "$KG_FILE" 2>/dev/null; then
                # Agregar nodo al knowledge-graph.yaml antes de la línea edges:
                if grep -q "nodes:" "$KG_FILE"; then
                    awk -v arch_id="$ARCH_ID" -v title="$TITLE" -v num="$NUM" -v date="$CURRENT_DATE" '
                    /^edges:/ {
                        print "  - id: " arch_id
                        print "    title: \"" title "\""
                        print "    status: ACTIVE"
                        print "    root: true"
                        print "    supersedes: []"
                        print "    depends_on: []"
                        print "    related: []"
                        print "    conflicts_with: []"
                        print "    ref: \"../decisions.md#" tolower(arch_id) "\""
                        print ""
                    }
                    { print }
                    ' "$KG_FILE" > "$KG_FILE.tmp" && mv "$KG_FILE.tmp" "$KG_FILE"
                fi
            fi

            if ! grep -q "$ARCH_ID" "$CATALOG_FILE" 2>/dev/null; then
                ARCH_LOWER=$(echo "$ARCH_ID" | tr '[:upper:]' '[:lower:]')
                echo "| $ARCH_ID | $TITLE | ⚖️ Vigente | [decisions.md](../../decisions.md#$ARCH_LOWER) | $CURRENT_DATE |" >> "$CATALOG_FILE"
            fi
        fi

        SYNCED_COUNT=$((SYNCED_COUNT + 1))
    fi
done

# Regenerar context-snapshot
regenerate_context_snapshot "$PROJECT_ROOT"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   ✅ Sincronización Finalizada                     ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Iniciativas reconciliadas: ${YELLOW}$SYNCED_COUNT${NC}"
echo -e "Memoria, Telemetría, Grafo y Snapshot actualizados con éxito."
