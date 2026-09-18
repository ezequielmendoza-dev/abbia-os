#!/usr/bin/env bash

# ==============================================================================
# validate-project.sh — Abbia OS Compliance Checker
# ==============================================================================
# Escanea el proyecto actual y verifica la estructura, convenciones de nombres
# y presencia de documentos obligatorios en la carpeta .abbia/ (o legacy .stratum/ / .ai/).
# Retorna código de salida 1 en caso de violaciones críticas (útil para CI/CD).
#
# Uso:
#   bash validate-project.sh
#   ./abbia validate
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
echo -e "${CYAN}   🔍 Validador de Estructura (Abbia OS v4.0.0)     ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Escaneando raíz de proyecto: ${YELLOW}$PROJECT_ROOT${NC}"

if [ ! -d "$ABBIA_DIR" ]; then
    echo -e "${RED}Error Crítico: No se encontró la carpeta documental (${ABBIA_DIR#$PROJECT_ROOT/}) en $PROJECT_ROOT${NC}"
    exit 1
fi

ERRORS=0
WARNINGS=0

error_found() {
    local msg="$1"
    echo -e "  [${RED}ERROR${NC}] $msg"
    ERRORS=$((ERRORS + 1))
}

warning_found() {
    local msg="$1"
    echo -e "  [${YELLOW}WARN${NC}]  $msg"
    WARNINGS=$((WARNINGS + 1))
}

if [ "$ABBIA_IS_LEGACY" = true ]; then
    warning_found "El proyecto utiliza la estructura legacy ($(basename "$ABBIA_DIR")). Se recomienda ejecutar 'bash $(basename "$ABBIA_DIR")/core/scripts/migrate-to-abbia.sh' para migrar a Abbia OS v4.0.0 (.abbia/)."
fi

# 1. Validar documentos permanentes
echo -e "\n${BLUE}Verificando documentos permanentes en ${ABBIA_DIR#$PROJECT_ROOT/}...${NC}"

PERMANENT_FILES=("context.md" "business-rules.md" "architecture.md" "decisions.md" "glossary.md")
for f in "${PERMANENT_FILES[@]}"; do
    FILE_PATH="$ABBIA_DIR/$f"
    if [ -f "$FILE_PATH" ]; then
        SIZE=$(wc -c < "$FILE_PATH" || echo 0)
        if [ "$SIZE" -lt 10 ]; then
            warning_found "El archivo ${ABBIA_DIR#$PROJECT_ROOT/}/$f existe pero está casi vacío."
        else
            echo -e "  [${GREEN}OK${NC}]    ${ABBIA_DIR#$PROJECT_ROOT/}/$f verificado."
        fi
    else
        error_found "Falta el archivo permanente obligatorio: ${ABBIA_DIR#$PROJECT_ROOT/}/$f"
    fi
done

# 2. Validar sistemas de Abbia OS
echo -e "\n${BLUE}Verificando sistemas Abbia OS (Memoria 3-Tier, Métricas y Knowledge Graph)...${NC}"

if [ -f "$ABBIA_DIR/knowledge-graph.yaml" ]; then
    KG_NODES=$(grep -cE '^[[:space:]]*- id: ARCH-[0-9]{3}' "$ABBIA_DIR/knowledge-graph.yaml" || true)
    KG_TEMPLATE_TITLE=$(grep -cE '^[[:space:]]*title: "Nombre corto de la decisión"' "$ABBIA_DIR/knowledge-graph.yaml" || true)
    REAL_KG_NODES=$((KG_NODES - KG_TEMPLATE_TITLE))
    if [ "$REAL_KG_NODES" -lt 0 ]; then REAL_KG_NODES=0; fi

    if [ "$REAL_KG_NODES" -gt 0 ]; then
        echo -e "  [${GREEN}OK${NC}]    ${ABBIA_DIR#$PROJECT_ROOT/}/knowledge-graph.yaml verificado ($REAL_KG_NODES nodo(s) activo(s))."
    else
        warning_found "${ABBIA_DIR#$PROJECT_ROOT/}/knowledge-graph.yaml existe pero sin nodos reales."
    fi
else
    warning_found "No existe ${ABBIA_DIR#$PROJECT_ROOT/}/knowledge-graph.yaml."
fi

if [ -d "$ABBIA_MEMORY_DIR" ]; then
    MEM_FILES=("workflow-log.md" "patterns-learned.md" "context-snapshot.md")
    MEM_OK=true
    for mf in "${MEM_FILES[@]}"; do
        if [ ! -f "$ABBIA_MEMORY_DIR/$mf" ]; then
            MEM_OK=false
            break
        fi
    done
    if [ "$MEM_OK" = true ]; then
        if grep -qE '^## \[(FEAT|BUG|AUDIT|REF)-[0-9]{3}\]' "$ABBIA_MEMORY_DIR/workflow-log.md"; then
            echo -e "  [${GREEN}OK${NC}]    ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/ verificado (con entradas en workflow-log)."
        else
            warning_found "${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/ existe pero workflow-log.md no tiene entradas de sesión."
        fi
    else
        warning_found "La carpeta ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/ existe pero le faltan archivos seed."
    fi
else
    warning_found "No existe la carpeta ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}."
fi

if [ -f "$ABBIA_METRICS_DIR/executions.yaml" ]; then
    if grep -qE '^  - ts: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$ABBIA_METRICS_DIR/executions.yaml"; then
        echo -e "  [${GREEN}OK${NC}]    ${ABBIA_METRICS_DIR#$PROJECT_ROOT/}/executions.yaml verificado (con ejecuciones)."
    else
        warning_found "${ABBIA_METRICS_DIR#$PROJECT_ROOT/}/executions.yaml existe pero no tiene ejecuciones registradas."
    fi
else
    warning_found "No existe ${ABBIA_METRICS_DIR#$PROJECT_ROOT/}/executions.yaml."
fi

# 3. Validar Estructura de Iniciativas Activas
if [ -d "$ABBIA_INITIATIVES_DIR" ]; then
    echo -e "\n${BLUE}Verificando iniciativas activas en ${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}...${NC}"
    
    shopt -s nullglob
    dirs=("$ABBIA_INITIATIVES_DIR"/*/)
    shopt -u nullglob
    
    if [ ${#dirs[@]} -eq 0 ]; then
        echo -e "  [${GREEN}INFO${NC}]  No hay iniciativas activas en progreso."
    fi

    if [ ${#dirs[@]} -gt 0 ]; then
        for dir in "${dirs[@]}"; do
            folder_name=$(basename "$dir")
            [ "$folder_name" = "*" ] && continue
            
            INITIATIVE_PATTERN="$(initiative_name_pattern)"
            READABLE_TYPES="$(initiative_types_readable)"
            if [[ ! "$folder_name" =~ $INITIATIVE_PATTERN ]]; then
                error_found "El nombre de la carpeta '$folder_name' no sigue el patrón '<$READABLE_TYPES>-<ID>-<slug>' (ej: FEAT-001-seat-layout)."
                continue
            fi
            
            TYPE=$(echo "$folder_name" | cut -d'-' -f1)
            REQ_FILES="$(required_files_for "$TYPE")"
            if [ -n "$REQ_FILES" ]; then
                for req in $REQ_FILES; do
                    if [ ! -f "$dir/$req" ]; then
                        error_found "Iniciativa '$TYPE' '$folder_name' no contiene el archivo obligatorio '$req'."
                    fi
                done
            else
                if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
                    error_found "Iniciativa '$folder_name' está vacía. Debe contener al menos un documento."
                else
                    echo -e "  [${GREEN}OK${NC}]    '$folder_name' (estructura libre) verificada."
                fi
            fi
            
            if [ "$TYPE" = "FEAT" ]; then
                if [ -f "$dir/spec.md" ] && (grep -q "FEAT-XXX" "$dir/spec.md" || grep -q "\[nombre\]" "$dir/spec.md"); then
                    warning_found "Feature '$folder_name' contiene placeholders de plantilla en spec.md."
                fi
            fi

            if [ "$TYPE" = "FEAT" ] || [ "$TYPE" = "BUG" ]; then
                QA_FILE="$dir/qa.md"
                if [ -f "$QA_FILE" ]; then
                    if ! grep -qiE "(Veredicto.*(APROBADO|RECHAZADO|PASS|FAIL)|Verdict.*(APPROVED|REJECTED|PASS|FAIL))" "$QA_FILE"; then
                        warning_found "Iniciativa '$folder_name' tiene qa.md pero no declara un veredicto explícito (APROBADO/RECHAZADO)."
                    fi
                fi
            fi
        done
    fi
else
    error_found "No existe el directorio de iniciativas en ${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}."
fi

# 4. Validar Estructura de Historial
if [ -d "$ABBIA_ARCHIVE_DIR" ]; then
    echo -e "\n${BLUE}Verificando iniciativas archivadas en ${ABBIA_ARCHIVE_DIR#$PROJECT_ROOT/}...${NC}"
    
    shopt -s nullglob
    archived_dirs=("$ABBIA_ARCHIVE_DIR"/*/)
    shopt -u nullglob
    
    if [ ${#archived_dirs[@]} -gt 0 ]; then
        for dir in "${archived_dirs[@]}"; do
            folder_name=$(basename "$dir")
            [ "$folder_name" = "*" ] && continue
            
            INITIATIVE_PATTERN="$(initiative_name_pattern)"
            READABLE_TYPES="$(initiative_types_readable)"
            if [[ ! "$folder_name" =~ $INITIATIVE_PATTERN ]]; then
                error_found "Archivo: El nombre de la carpeta archivada '$folder_name' no sigue el patrón '<$READABLE_TYPES>-<ID>-<slug>'."
                continue
            fi

            ARCH_TYPE=$(echo "$folder_name" | cut -d'-' -f1)
            ARCH_REQ_FILES="$(required_archived_files_for "$ARCH_TYPE")"
            if [ -n "$ARCH_REQ_FILES" ]; then
                for req in $ARCH_REQ_FILES; do
                    if [ ! -f "$dir/$req" ]; then
                        warning_found "Iniciativa archivada '$folder_name' no contiene el archivo de cierre '$req'."
                    fi
                done
            fi
        done
    fi
fi

# 5. Validar Higiene de Git
if [ -d "$PROJECT_ROOT/.git" ] || git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
    echo -e "\n${BLUE}Verificando higiene de Git (.gitignore y .gitattributes)...${NC}"
    
    target_prefix="${ABBIA_DIR#$PROJECT_ROOT/}"
    TRACKED_DERIVED=0
    for f in "$target_prefix/dashboard.html" "$target_prefix/memory/context-snapshot.md" "$target_prefix/metrics/aggregates.yaml"; do
        if git -C "$PROJECT_ROOT" ls-files --error-unmatch "$f" &>/dev/null; then
            warning_found "El archivo generado/caché '$f' está siendo rastreado por Git. Ignorar con: git rm --cached $f"
            TRACKED_DERIVED=$((TRACKED_DERIVED + 1))
        fi
    done

    GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
    if [ -f "$GITIGNORE_FILE" ]; then
        echo -e "  [${GREEN}OK${NC}]    .gitignore verificado."
    else
        warning_found "No se encontró .gitignore en la raíz del proyecto."
    fi
fi

# Reporte Final
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}   📊 Resumen de Validación                         ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Errores Críticos: ${RED}$ERRORS${NC}"
echo -e "Advertencias:     ${YELLOW}$WARNINGS${NC}"
echo -e "===================================================="

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ Validación Fallida.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Validación Exitosa. El proyecto cumple con la estructura y estándares de Abbia OS.${NC}"
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}Nota: Se encontraron advertencias no críticas recomendadas de atender.${NC}"
    fi
    exit 0
fi
