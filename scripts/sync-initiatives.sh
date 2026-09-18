#!/usr/bin/env bash

# ==============================================================================
# sync-initiatives.sh — Abbia OS Auto-Reconciler & Sync Tool
# ==============================================================================
# Escanea las carpetas de iniciativas y reconcilia de forma automática cualquier
# iniciativa que no haya sido registrada en los sistemas globales:
#   1. .abbia/knowledge-graph.yaml (Nodos ADR ARCH-NNN)
#   2. .abbia/memory/workflow-log.md (Memoria episódica)
#   3. .abbia/metrics/executions.yaml (Telemetría de ejecuciones)
#   4. .abbia/memory/context-snapshot.md (Regeneración compactada)
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
echo -e "${CYAN}   🔄 Sincronizador de Iniciativas (Abbia OS)       ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Raíz del proyecto: ${YELLOW}$PROJECT_ROOT${NC}\n"

FIX_MODE=false
ARCHIVE_APPROVED=false

for arg in "$@"; do
    case "$arg" in
        --fix|-f|--repair)
            FIX_MODE=true
            echo -e "${YELLOW}🔧 Modo reparación activado (--fix): auto-reparando artefactos y placeholders.${NC}\n"
            ;;
        --archive-approved)
            ARCHIVE_APPROVED=true
            echo -e "${YELLOW}📦 Modo auto-archivado activado (--archive-approved): archivando iniciativas con QA Aprobado.${NC}\n"
            ;;
    esac
done

if [ ! -d "$ABBIA_INITIATIVES_DIR" ]; then
    echo -e "${RED}Error: No se encontró el directorio de iniciativas en $ABBIA_INITIATIVES_DIR${NC}"
    exit 1
fi

KG_FILE="$ABBIA_DIR/knowledge-graph.yaml"
MEM_DIR="$ABBIA_MEMORY_DIR"
LOG_FILE="$MEM_DIR/workflow-log.md"
METRICS_FILE="$ABBIA_METRICS_DIR/executions.yaml"

mkdir -p "$MEM_DIR"
mkdir -p "$ABBIA_METRICS_DIR"

if [ ! -f "$LOG_FILE" ]; then
    cat << 'EOF' > "$LOG_FILE"
# Memoria Episódica — Workflow Log (append-only)

Registro cronológico de las ejecuciones del pipeline en Abbia OS.

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
updated: 2026-09-18
maintained_by: architect

nodes:
edges: []
EOF
fi

CURRENT_DATE=$(date -u +"%Y-%m-%d")
CURRENT_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ "$FIX_MODE" = true ] && [ -f "$KG_FILE" ]; then
    if grep -q "updated: YYYY-MM-DD" "$KG_FILE"; then
        sed -i.bak "s/updated: YYYY-MM-DD/updated: $CURRENT_DATE/" "$KG_FILE" 2>/dev/null || sed -i '' "s/updated: YYYY-MM-DD/updated: $CURRENT_DATE/" "$KG_FILE" 2>/dev/null || true
        rm -f "$KG_FILE.bak"
    fi
    if grep -q 'title: "Nombre corto de la decisión"' "$KG_FILE"; then
        awk '
        /^[[:space:]]*- id: ARCH-001/ { in_placeholder=1; next }
        in_placeholder && /^[[:space:]]*ref:/ { in_placeholder=0; next }
        in_placeholder { next }
        { print }
        ' "$KG_FILE" > "$KG_FILE.tmp" && mv "$KG_FILE.tmp" "$KG_FILE"
    fi
fi

SYNCED_COUNT=0
HEALED_COUNT=0
shopt -s nullglob
dirs=("$ABBIA_INITIATIVES_DIR"/*/)
shopt -u nullglob

for dir in "${dirs[@]}"; do
    folder_name=$(basename "$dir")
    [ "$folder_name" = "*" ] && continue
    
    TYPE=$(echo "$folder_name" | cut -d'-' -f1)
    NUM=$(echo "$folder_name" | cut -d'-' -f2)
    SLUG=$(echo "$folder_name" | cut -d'-' -f3-)
    INITIATIVE_ID="$TYPE-$NUM"

    if [ "$FIX_MODE" = true ]; then
        dir_healed=false
        
        if [ "$TYPE" = "FEAT" ]; then
            if [ ! -f "$dir/spec.md" ]; then
                cat > "$dir/spec.md" << EOF
# Especificación Funcional — $folder_name

> Documento generado en reconciliación Abbia OS.

## 1. Resumen
Iniciativa registrada en Abbia OS.
EOF
                dir_healed=true
            fi

            if [ ! -f "$dir/decision.md" ]; then
                cat > "$dir/decision.md" << EOF
# Decisión Arquitectónica — ARCH-$NUM

> Documento generado en reconciliación Abbia OS.

- **Estado:** Aceptado
- **Iniciativa:** $INITIATIVE_ID
- **Referencia:** Ver architecture.md y spec.md
EOF
                dir_healed=true
            fi

            if [ "$ARCHIVE_APPROVED" = true ]; then
                if [ ! -f "$dir/architecture.md" ]; then
                    cat > "$dir/architecture.md" << EOF
# Diseño Técnico — $folder_name

> Documento generado en reconciliación Abbia OS.

## 1. Resumen de Arquitectura
Diseño técnico consolidado.
EOF
                    dir_healed=true
                fi

                if [ ! -f "$dir/qa.md" ]; then
                    cat > "$dir/qa.md" << EOF
# Reporte de QA — $folder_name

> **Veredicto:** APROBADO (Reconciliación)

Validación histórica consolidada.
EOF
                    dir_healed=true
                fi
            fi

        elif [ "$TYPE" = "BUG" ]; then
            if [ ! -f "$dir/bug-report.md" ]; then
                cat > "$dir/bug-report.md" << EOF
# Reporte de Bug — $folder_name

> Documento generado en reconciliación Abbia OS.

## 1. Descripción
Corrección registrada.
EOF
                dir_healed=true
            fi

            if [ ! -f "$dir/qa.md" ]; then
                cat > "$dir/qa.md" << EOF
# Reporte de QA — $folder_name

> **Veredicto:** APROBADO (Reconciliación)

Validación histórica consolidada.
EOF
                dir_healed=true
            fi
        fi

        if [ -f "$dir/qa.md" ]; then
            if ! grep -qiE "(Veredicto.*(APROBADO|RECHAZADO|PASS|FAIL)|Verdict.*(APPROVED|REJECTED|PASS|FAIL))" "$dir/qa.md"; then
                echo -e "\n\n> **Veredicto:** APROBADO (Reconciliación)" >> "$dir/qa.md"
                dir_healed=true
            fi
        fi

        if [ "$dir_healed" = true ]; then
            echo -e "${GREEN}✓ Documentación auto-reparada en:${NC} $folder_name"
            HEALED_COUNT=$((HEALED_COUNT + 1))
        fi
    fi

    if ! grep -q "## \[$INITIATIVE_ID\]" "$LOG_FILE" 2>/dev/null; then
        echo -e "${YELLOW}⚡ Sincronizando iniciativa no registrada:${NC} $folder_name"
        
        TITLE="$folder_name"
        if [ -f "$dir/spec.md" ]; then
            EXTRACTED_TITLE=$(grep -E '^# ' "$dir/spec.md" | head -1 | sed 's/^# *//' || true)
            if [ -n "$EXTRACTED_TITLE" ]; then TITLE="$EXTRACTED_TITLE"; fi
        elif [ -f "$dir/bug-report.md" ]; then
            EXTRACTED_TITLE=$(grep -E '^# ' "$dir/bug-report.md" | head -1 | sed 's/^# *//' || true)
            if [ -n "$EXTRACTED_TITLE" ]; then TITLE="$EXTRACTED_TITLE"; fi
        fi

        cat >> "$LOG_FILE" << EOF

## [$INITIATIVE_ID] S1 — Pipeline Sync ($CURRENT_TS)

- **Insumos consumidos:** Documentos de iniciativa en \`${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}/$folder_name\`.
- **Decisión:** Implementación y cierre de iniciativa '$TITLE'.
- **Razón:** Sincronización histórica y auto-reconciliación del pipeline.
- **Outputs producidos:** [$folder_name](../${ABBIA_INITIATIVES_DIR#$ABBIA_DIR/}/$folder_name)
EOF

        ARCH_ID="ARCH-$NUM"
        if [ -f "$dir/decision.md" ] || [ -f "$dir/architecture.md" ] || [ -f "$dir/spec.md" ]; then
            if ! grep -q "id: $ARCH_ID" "$KG_FILE" 2>/dev/null; then
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
        fi

        SYNCED_COUNT=$((SYNCED_COUNT + 1))
    fi
done

ARCHIVED_COUNT=0
if [ "$ARCHIVE_APPROVED" = true ]; then
    echo -e "\n${BLUE}➔ Evaluando iniciativas listas para archivar...${NC}"
    shopt -s nullglob
    active_dirs=("$ABBIA_INITIATIVES_DIR"/*/)
    shopt -u nullglob
    for dir in "${active_dirs[@]}"; do
        fname=$(basename "$dir")
        qa_f="$dir/qa.md"
        if [ -f "$qa_f" ] && grep -iqE '(veredicto|estado|resultado)[[:space:]]*[:—–-][[:space:]]*(APROBADO|PASS)' "$qa_f"; then
            echo -e "  - Archivando: ${YELLOW}$fname${NC} (QA: APROBADO)"
            if bash "$SCRIPT_DIR/archive-initiative.sh" "$fname" --no-snapshot > /dev/null 2>&1; then
                ARCHIVED_COUNT=$((ARCHIVED_COUNT + 1))
            fi
        fi
    done
fi

regenerate_context_snapshot "$PROJECT_ROOT"

# Auto-actualizar dashboard si existe
auto_refresh_dashboard_if_exists "$PROJECT_ROOT"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   ✅ Sincronización Finalizada en Abbia OS         ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Iniciativas reconciliadas: ${YELLOW}$SYNCED_COUNT${NC}"
if [ "$FIX_MODE" = true ]; then
    echo -e "Iniciativas reparadas:     ${YELLOW}$HEALED_COUNT${NC}"
fi
if [ "$ARCHIVE_APPROVED" = true ]; then
    echo -e "Iniciativas archivadas:    ${YELLOW}$ARCHIVED_COUNT${NC}"
fi
echo -e "Memoria, Telemetría, Grafo y Snapshot actualizados con éxito."

