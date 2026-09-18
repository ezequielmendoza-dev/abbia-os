#!/usr/bin/env bash

# ==============================================================================
# validate-project.sh — ai-agents OS Compliance Checker
# ==============================================================================
# Escanea el proyecto actual y verifica la estructura, convenciones de nombres
# y presencia de documentos obligatorios en la carpeta .ai/ de acuerdo a las
# reglas R1-R5.
# Retorna código de salida 1 en caso de violaciones críticas (útil para CI/CD).
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

# 1. Determinar rutas y directorios
PROJECT_ROOT="$(detect_project_root)"

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🔍 Validador de Estructura (ai-agents OS)        ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Escaneando raíz de proyecto: ${YELLOW}$PROJECT_ROOT${NC}"

# Validar existencia de .ai/
if [ ! -d "$PROJECT_ROOT/.ai" ]; then
    echo -e "${RED}Error Crítico: No se encontró la carpeta documental .ai/ en $PROJECT_ROOT${NC}"
    exit 1
fi

# Contadores de incidencias
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

# 2. Validar archivos permanentes obligatorios
echo -e "\n${BLUE}Verificando documentos permanentes en .ai/...${NC}"

PERMANENT_FILES=("context.md" "business-rules.md" "architecture.md" "decisions.md" "glossary.md")
for f in "${PERMANENT_FILES[@]}"; do
    FILE_PATH="$PROJECT_ROOT/.ai/$f"
    if [ -f "$FILE_PATH" ]; then
        # Verificar que no esté vacío (al menos 10 bytes)
        SIZE=$(wc -c < "$FILE_PATH" || echo 0)
        if [ "$SIZE" -lt 10 ]; then
            warning_found "El archivo .ai/$f existe pero está vacío o casi vacío. Debería completarse."
        else
            echo -e "  [${GREEN}OK${NC}]    .ai/$f verificado."
        fi
    else
        error_found "Falta el archivo permanente obligatorio: .ai/$f"
    fi
done

# 3. Validar Sistemas de v3.2.0 (memoria, métricas, knowledge graph) — WARN no bloqueante
# Compatible con proyectos anteriores a v3.2.0: la ausencia se reporta como advertencia.
# Además de existencia, se valida CONTENIDO: un sistema seedeado pero nunca usado (template
# o archivo vacío) se reporta como advertencia para distinguir "existe" de "tiene datos".
echo -e "\n${BLUE}Verificando sistemas opcionales de v3.2.0 en .ai/...${NC}"

if [ -f "$PROJECT_ROOT/.ai/knowledge-graph.yaml" ]; then
    # Contenido: un grafo útil tiene al menos un nodo ARCH-NNN real
    KG_NODES=$(grep -cE '^[[:space:]]*- id: ARCH-[0-9]{3}' "$PROJECT_ROOT/.ai/knowledge-graph.yaml" || true)
    KG_TEMPLATE_TITLE=$(grep -cE '^[[:space:]]*title: "Nombre corto de la decisión"' "$PROJECT_ROOT/.ai/knowledge-graph.yaml" || true)
    
    # Nodos reales = nodos totales menos los placeholders de ejemplo
    REAL_KG_NODES=$((KG_NODES - KG_TEMPLATE_TITLE))
    if [ "$REAL_KG_NODES" -lt 0 ]; then REAL_KG_NODES=0; fi

    if [ "$REAL_KG_NODES" -gt 0 ]; then
        echo -e "  [${GREEN}OK${NC}]    .ai/knowledge-graph.yaml verificado ($REAL_KG_NODES nodo(s) activo(s))."
        # Validación semántica: verificar que dependencias sigan el formato ARCH-NNN
        INVALID_REFS=$(grep -E '^[[:space:]]*(depends_on|supersedes|conflicts_with):' "$PROJECT_ROOT/.ai/knowledge-graph.yaml" | grep -v '\[\]' | grep -E '\[.*\]' | grep -vE '\[(ARCH-[0-9]{3}(, *ARCH-[0-9]{3})*)\]' || true)
        if [ -n "$INVALID_REFS" ]; then
            warning_found "El grafo de decisiones contiene dependencias con formato no estándar: $INVALID_REFS (debe ser [ARCH-NNN])."
        fi
    else
        warning_found ".ai/knowledge-graph.yaml existe pero sin nodos reales (solo el template). Registrar los ARCH-NNN (o usar sync-initiatives.sh --fix)."
    fi
else
    warning_found "No existe .ai/knowledge-graph.yaml. El grafo de decisiones está inactivo (opcional v3.2.0)."
fi

MEMORY_DIR="$PROJECT_ROOT/.ai/memory"
if [ -d "$MEMORY_DIR" ]; then
    MEM_FILES=("workflow-log.md" "patterns-learned.md" "context-snapshot.md")
    MEM_OK=true
    for mf in "${MEM_FILES[@]}"; do
        if [ ! -f "$MEMORY_DIR/$mf" ]; then
            MEM_OK=false
            break
        fi
    done
    if [ "$MEM_OK" = true ]; then
        # Contenido: validar que workflow-log tenga al menos una entrada de sesión real
        if grep -qE '^## \[(FEAT|BUG|AUDIT|REF)-[0-9]{3}\]' "$MEMORY_DIR/workflow-log.md"; then
            echo -e "  [${GREEN}OK${NC}]    .ai/memory/ verificado (con entradas en workflow-log)."
        else
            warning_found ".ai/memory/ existe pero workflow-log.md no tiene entradas de sesión (solo el template). Registrar cada fase con finish-phase.sh."
        fi
    else
        warning_found "La carpeta .ai/memory/ existe pero le faltan archivos seed (workflow-log.md, patterns-learned.md, context-snapshot.md)."
    fi
else
    warning_found "No existe la carpeta .ai/memory/. La memoria persistente está inactiva (opcional v3.2.0)."
fi

if [ -f "$PROJECT_ROOT/.ai/metrics/executions.yaml" ]; then
    # Contenido: una ejecución real tiene `ts: AAAA-MM-DD` (no el placeholder YYYY-MM-DD)
    if grep -qE '^  - ts: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$PROJECT_ROOT/.ai/metrics/executions.yaml"; then
        echo -e "  [${GREEN}OK${NC}]    .ai/metrics/executions.yaml verificado (con ejecuciones)."
    else
        warning_found ".ai/metrics/executions.yaml existe pero no tiene ejecuciones registradas (solo el template). Registrarlas con finish-phase.sh."
    fi
else
    warning_found "No existe .ai/metrics/executions.yaml. Las métricas del pipeline están inactivas (opcional v3.2.0)."
fi

# 4. Validar Estructura de Características Activas (.ai/features/)
FEATURES_DIR="$PROJECT_ROOT/.ai/features"
if [ -d "$FEATURES_DIR" ]; then
    echo -e "\n${BLUE}Verificando iniciativas activas en .ai/features/...${NC}"
    
    # Obtener subdirectorios de primer nivel
    # Usar find para listar solo directorios para evitar problemas con globs vacíos
    shopt -s nullglob
    dirs=("$FEATURES_DIR"/*/)
    shopt -u nullglob
    
    if [ ${#dirs[@]} -eq 0 ]; then
        echo -e "  [${GREEN}INFO${NC}]  No hay iniciativas activas en progreso."
    fi

    if [ ${#dirs[@]} -gt 0 ]; then
        for dir in "${dirs[@]}"; do
        # Obtener el nombre de la carpeta (sin barra final)
        folder_name=$(basename "$dir")
        
        # Validar nomenclatura central (<FEAT|BUG|AUDIT|REF>-<ID>-<slug>)
        INITIATIVE_PATTERN="$(initiative_name_pattern)"
        READABLE_TYPES="$(initiative_types_readable)"
        if [[ ! "$folder_name" =~ $INITIATIVE_PATTERN ]]; then
            error_found "El nombre de la carpeta '$folder_name' no sigue el patrón '<$READABLE_TYPES>-<ID>-<slug>' (ej: FEAT-001-seat-layout)."
            continue
        fi
        
        # Determinar tipo
        TYPE=$(echo "$folder_name" | cut -d'-' -f1)
        
        # Validar archivos internos obligatorios por tipo (en minúsculas)
        REQ_FILES="$(required_files_for "$TYPE")"
        if [ -n "$REQ_FILES" ]; then
            for req in $REQ_FILES; do
                if [ ! -f "$dir/$req" ]; then
                    error_found "Iniciativa '$TYPE' '$folder_name' no contiene el archivo obligatorio '$req'."
                fi
            done
        else
            # Tipos de estructura libre (AUDIT, REF): solo verificar que no esté vacía
            if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
                error_found "Iniciativa '$folder_name' está vacía. Debe contener al menos un documento."
            else
                echo -e "  [${GREEN}OK${NC}]    '$folder_name' (estructura libre) verificada."
            fi
        fi
        
        # Validaciones Semánticas por Archivo
        if [ "$TYPE" = "FEAT" ]; then
            SPEC_FILE="$dir/spec.md"
            if [ -f "$SPEC_FILE" ]; then
                if grep -q "FEAT-XXX" "$SPEC_FILE" || grep -q "\[nombre\]" "$SPEC_FILE"; then
                    warning_found "Feature '$folder_name' contiene placeholders de plantilla (FEAT-XXX / [nombre]) en spec.md."
                fi
            fi

            ARCH_FILE="$dir/architecture.md"
            if [ -f "$ARCH_FILE" ]; then
                if grep -q "FEAT-XXX" "$ARCH_FILE" || grep -q "\[nombre\]" "$ARCH_FILE"; then
                    warning_found "Feature '$folder_name' contiene placeholders de plantilla en architecture.md."
                fi
            fi

            UI_FILE="$dir/ui-design.md"
            if [ -f "$UI_FILE" ]; then
                if grep -q "FEAT-XXX" "$UI_FILE" || grep -q "\[nombre\]" "$UI_FILE"; then
                    warning_found "Feature '$folder_name' contiene placeholders de plantilla en ui-design.md."
                fi
            fi
        fi

        # Validación semántica de qa.md (FEAT y BUG)
        if [ "$TYPE" = "FEAT" ] || [ "$TYPE" = "BUG" ]; then
            QA_FILE="$dir/qa.md"
            if [ -f "$QA_FILE" ]; then
                if ! grep -qiE "(Veredicto.*(APROBADO|RECHAZADO|PASS|FAIL)|Verdict.*(APPROVED|REJECTED|PASS|FAIL))" "$QA_FILE"; then
                    warning_found "Iniciativa '$folder_name' tiene qa.md pero no declara un veredicto explícito (APROBADO/RECHAZADO)."
                fi
            fi
        fi

        # Verificación de sincronización con el sistema de memoria
        if [ -f "$PROJECT_ROOT/.ai/memory/workflow-log.md" ]; then
            INITIATIVE_SHORT_ID=$(echo "$folder_name" | cut -d'-' -f1,2)
            if ! grep -q "## \[$INITIATIVE_SHORT_ID\]" "$PROJECT_ROOT/.ai/memory/workflow-log.md" 2>/dev/null; then
                warning_found "Iniciativa '$folder_name' no tiene entradas en .ai/memory/workflow-log.md. Registrar con finish-phase.sh o sincronizar con sync-initiatives.sh."
            fi
        fi
    done
    fi
else
    error_found "No existe el directorio .ai/features/. Es requerido por el sistema documental."
fi

# 5. Validar Estructura de Historial (.ai/archive/)
ARCHIVE_DIR="$PROJECT_ROOT/.ai/archive"
if [ -d "$ARCHIVE_DIR" ]; then
    echo -e "\n${BLUE}Verificando iniciativas archivadas en .ai/archive/...${NC}"
    
    shopt -s nullglob
    archived_dirs=("$ARCHIVE_DIR"/*/)
    shopt -u nullglob
    
    if [ ${#archived_dirs[@]} -eq 0 ]; then
        echo -e "  [${GREEN}INFO${NC}]  No hay iniciativas archivadas."
    fi

    if [ ${#archived_dirs[@]} -gt 0 ]; then
    for dir in "${archived_dirs[@]}"; do
        folder_name=$(basename "$dir")
        
        # Validar nomenclatura central
        INITIATIVE_PATTERN="$(initiative_name_pattern)"
        READABLE_TYPES="$(initiative_types_readable)"
        if [[ ! "$folder_name" =~ $INITIATIVE_PATTERN ]]; then
            error_found "Archivo: El nombre de la carpeta archivada '$folder_name' no sigue el patrón '<$READABLE_TYPES>-<ID>-<slug>'."
            continue
        fi

        # Determinar tipo y validar artefactos de cierre en iniciativas archivadas
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
else
    warning_found "No existe el directorio .ai/archive/. Se recomienda crearlo para almacenar el historial de features cerradas."
fi

# 6. Validar Higiene de Git (.gitignore y .gitattributes)
if [ -d "$PROJECT_ROOT/.git" ] || git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
    echo -e "\n${BLUE}Verificando higiene de Git (.gitignore y .gitattributes)...${NC}"
    
    # 6.1 Verificar si archivos derivados/caché están siendo rastreados por Git
    TRACKED_DERIVED=0
    for f in ".ai/dashboard.html" ".ai/memory/context-snapshot.md" ".ai/metrics/aggregates.yaml"; do
        if git -C "$PROJECT_ROOT" ls-files --error-unmatch "$f" &>/dev/null; then
            warning_found "El archivo generado/caché '$f' está siendo rastreado por Git. Debe ignorarse para evitar conflictos: git rm --cached $f"
            TRACKED_DERIVED=$((TRACKED_DERIVED + 1))
        fi
    done
    if [ $TRACKED_DERIVED -eq 0 ]; then
        echo -e "  [${GREEN}OK${NC}]    No hay archivos generados/caché rastreados por Git."
    fi

    # 6.2 Verificar .gitignore
    GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
    if [ -f "$GITIGNORE_FILE" ]; then
        MISSING_GI=0
        for entry in ".ai/sessions/" ".ai/dashboard.html" ".ai/memory/context-snapshot.md" ".ai/metrics/aggregates.yaml"; do
            if ! grep -qF "$entry" "$GITIGNORE_FILE"; then
                MISSING_GI=$((MISSING_GI + 1))
            fi
        done
        if [ $MISSING_GI -gt 0 ]; then
            warning_found ".gitignore no contiene todas las exclusiones recomendadas de ai-agents. Ejecutar 'setup-ide.sh' para completarlo."
        else
            echo -e "  [${GREEN}OK${NC}]    .gitignore verificado con exclusiones de ai-agents."
        fi
    else
        warning_found "No se encontró .gitignore en la raíz del proyecto."
    fi

    # 6.3 Verificar .gitattributes (merge=union)
    GITATTR_FILE="$PROJECT_ROOT/.gitattributes"
    if [ -f "$GITATTR_FILE" ]; then
        if grep -qF ".ai/memory/workflow-log.md merge=union" "$GITATTR_FILE" && grep -qF ".ai/metrics/executions.yaml merge=union" "$GITATTR_FILE"; then
            echo -e "  [${GREEN}OK${NC}]    .gitattributes verificado con directivas merge=union."
        else
            warning_found ".gitattributes no tiene configurado 'merge=union' para workflow-log.md y executions.yaml. Ejecutar 'setup-ide.sh' para configurarlo."
        fi
    else
        warning_found "No se encontró .gitattributes en el proyecto. Recomendado para prevenir conflictos en logs append-only."
    fi
fi

# 7. Reporte Final
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}   📊 Resumen de Validación                         ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Errores Críticos: ${RED}$ERRORS${NC}"
echo -e "Advertencias:     ${YELLOW}$WARNINGS${NC}"
echo -e "===================================================="

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ Validación Fallida. Se detectaron incumplimientos críticos de la estructura documental.${NC}"
    echo -e "\n${YELLOW}💡 Tip: Si estás migrando un proyecto con iniciativas creadas en versiones previas a v3.2, puedes auto-reparar la estructura ejecutando:${NC}"
    echo -e "${YELLOW}   bash .ai/agents/scripts/sync-initiatives.sh --fix${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Validación Exitosa. El proyecto cumple con la estructura y nomenclatura de ai-agents OS.${NC}"
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}Nota: Se encontraron advertencias no críticas que se recomienda corregir.${NC}"
    fi
    exit 0
fi
