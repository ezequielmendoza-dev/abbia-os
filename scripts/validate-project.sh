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
echo -e "\n${BLUE}Verificando sistemas opcionales de v3.2.0 en .ai/...${NC}"

if [ -f "$PROJECT_ROOT/.ai/knowledge-graph.yaml" ]; then
    echo -e "  [${GREEN}OK${NC}]    .ai/knowledge-graph.yaml verificado."
else
    warning_found "No existe .ai/knowledge-graph.yaml. El grafo de decisiones está inactivo (opcional v3.2.0)."
fi

MEMORY_DIR="$PROJECT_ROOT/.ai/memory"
if [ -d "$MEMORY_DIR" ]; then
    MEM_FILES=("workflow-log.md" "decisions-catalog.md" "patterns-learned.md" "context-snapshot.md")
    MEM_OK=true
    for mf in "${MEM_FILES[@]}"; do
        if [ ! -f "$MEMORY_DIR/$mf" ]; then
            MEM_OK=false
            break
        fi
    done
    if [ "$MEM_OK" = true ]; then
        echo -e "  [${GREEN}OK${NC}]    .ai/memory/ verificado (workflow-log, decisions-catalog, patterns-learned, context-snapshot)."
    else
        warning_found "La carpeta .ai/memory/ existe pero le faltan archivos seed (workflow-log.md, decisions-catalog.md, patterns-learned.md, context-snapshot.md)."
    fi
else
    warning_found "No existe la carpeta .ai/memory/. La memoria persistente está inactiva (opcional v3.2.0)."
fi

if [ -f "$PROJECT_ROOT/.ai/metrics/executions.yaml" ]; then
    echo -e "  [${GREEN}OK${NC}]    .ai/metrics/executions.yaml verificado."
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
        
        # Validar nomenclatura (FEAT-NNN-slug o BUG-NNN-slug)
        if [[ ! "$folder_name" =~ ^(FEAT|BUG)-[0-9]{3}-[a-z0-9-]+$ ]]; then
            error_found "El nombre de la carpeta '$folder_name' no sigue el patrón '<FEAT|BUG>-<ID>-<slug>' (ej: FEAT-001-seat-layout)."
            continue
        fi
        
        # Determinar tipo
        TYPE=$(echo "$folder_name" | cut -d'-' -f1)
        
        # Validar archivos internos obligatorios por tipo
        if [ "$TYPE" = "FEAT" ]; then
            # Archivos obligatorios para Feature
            REQ_FILES=("spec.md" "ui-design.md" "architecture.md" "qa.md" "decision.md")
            for req in "${REQ_FILES[@]}"; do
                if [ ! -f "$dir/$req" ]; then
                    error_found "Feature '$folder_name' no contiene el archivo obligatorio '$req'."
                fi
            done
            
            # Advertir si spec.md aún tiene placeholders de templates sin cambiar
            SPEC_FILE="$dir/spec.md"
            if [ -f "$SPEC_FILE" ]; then
                if grep -q "FEAT-XXX" "$SPEC_FILE" || grep -q "\[nombre\]" "$SPEC_FILE"; then
                    warning_found "Feature '$folder_name' contiene placeholders de plantilla (FEAT-XXX / [nombre]) en spec.md."
                fi
            fi
            
        elif [ "$TYPE" = "BUG" ]; then
            # Archivos obligatorios para Bug
            REQ_FILES=("bug-report.md" "qa.md")
            for req in "${REQ_FILES[@]}"; do
                if [ ! -f "$dir/$req" ]; then
                    error_found "Bug '$folder_name' no contiene el archivo obligatorio '$req'."
                fi
            done
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
        
        # Validar nomenclatura
        if [[ ! "$folder_name" =~ ^(FEAT|BUG)-[0-9]{3}-[a-z0-9-]+$ ]]; then
            error_found "Archivo: El nombre de la carpeta archivada '$folder_name' no sigue el patrón '<FEAT|BUG>-<ID>-<slug>'."
        fi
    done
    fi
else
    warning_found "No existe el directorio .ai/archive/. Se recomienda crearlo para almacenar el historial de features cerradas."
fi

# 6. Reporte Final
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}   📊 Resumen de Validación                         ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Errores Críticos: ${RED}$ERRORS${NC}"
echo -e "Advertencias:     ${YELLOW}$WARNINGS${NC}"
echo -e "===================================================="

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ Validación Fallida. Se detectaron incumplimientos críticos de la estructura documental.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Validación Exitosa. El proyecto cumple con la estructura y nomenclatura de ai-agents OS.${NC}"
    if [ "$WARNINGS" -gt 0 ]; then
        echo -e "${YELLOW}Nota: Se encontraron advertencias no críticas que se recomienda corregir.${NC}"
    fi
    exit 0
fi
