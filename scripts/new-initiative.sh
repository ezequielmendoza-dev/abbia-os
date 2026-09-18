#!/usr/bin/env bash

# ==============================================================================
# new-initiative.sh — ai-agents Initiative Bootstrapper
# ==============================================================================
# Automatiza el bootstrap de una nueva iniciativa (feature, bug, auditoría o
# refactor) en la carpeta .ai/features/ y actualiza el registro de IDs en
# .ai/context.md.
# Tipos soportados: FEAT (feature), BUG (bug), AUDIT (auditoría/seguridad),
# REF (refactor). FEAT y BUG generan templates completos; AUDIT y REF crean
# una carpeta con estructura libre.
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
echo -e "${BLUE}   🤖 Generador de Iniciativas (ai-agents OS)       ${NC}"
echo -e "${BLUE}====================================================${NC}"

# Validar que existe la carpeta .ai/
if [ ! -d "$PROJECT_ROOT/.ai" ]; then
    echo -e "${RED}Error: No se encontró la carpeta de configuración documental (.ai/) en la raíz del proyecto: $PROJECT_ROOT${NC}"
    echo -e "Asegúrate de ejecutar este script desde la raíz del proyecto o haber corrido primero 'setup-ide.sh'."
    exit 1
fi

# Variables de la iniciativa
TYPE=""
ID=""
SLUG=""

# Determinar modo de ejecución (argumentos vs interactivo)
if [ "$#" -ge 3 ]; then
    # Modo argumentos
    TYPE=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    ID="$2"
    SLUG="$3"
else
    # Modo interactivo
    echo "Selecciona el tipo de iniciativa:"
    echo "1) Nueva Feature (FEAT)"
    echo "2) Corrección de Bug (BUG)"
    echo "3) Auditoría / Seguridad (AUDIT)"
    echo "4) Refactor (REF)"
    read -p "Ingresa tu opción (1-4): " type_choice
    
    case "$type_choice" in
        "1") TYPE="FEAT" ;;
        "2") TYPE="BUG" ;;
        "3") TYPE="AUDIT" ;;
        "4") TYPE="REF" ;;
        *)
            echo -e "${RED}Opción inválida. Cancelando.${NC}"
            exit 1
            ;;
    esac
    
    # Determinar siguiente ID disponible escaneando filesystem (.ai/features y .ai/archive) y context.md
    MAX_FS_NUM=0
    for search_dir in "$PROJECT_ROOT/.ai/features" "$PROJECT_ROOT/.ai/archive"; do
        if [ -d "$search_dir" ]; then
            for folder in "$search_dir"/$TYPE-[0-9][0-9][0-9]*; do
                if [ -d "$folder" ]; then
                    bname=$(basename "$folder")
                    num_part=$(echo "$bname" | grep -oE "^$TYPE-[0-9]{3}" | cut -d'-' -f2 || true)
                    if [ -n "$num_part" ]; then
                        num_val=$((10#$num_part))
                        if [ $num_val -gt $MAX_FS_NUM ]; then
                            MAX_FS_NUM=$num_val
                        fi
                    fi
                fi
            done
        fi
    done

    MAX_CTX_NUM=0
    CONTEXT_FILE="$PROJECT_ROOT/.ai/context.md"
    if [ -f "$CONTEXT_FILE" ]; then
        LAST_ASSIGNED=$(grep -i "Último $TYPE asignado:" "$CONTEXT_FILE" | grep -oE "$TYPE-[0-9]+" | cut -d'-' -f2 || true)
        if [ -n "$LAST_ASSIGNED" ]; then
            MAX_CTX_NUM=$((10#$LAST_ASSIGNED))
        fi
    fi

    MAX_NUM=$(( MAX_FS_NUM > MAX_CTX_NUM ? MAX_FS_NUM : MAX_CTX_NUM ))
    NEXT_NUM=$(( MAX_NUM + 1 ))
    SUGGESTED_ID=$(printf "%03d" "$NEXT_NUM")
    echo -e "${GREEN}✓ Siguiente ID detectado dinámicamente: $SUGGESTED_ID${NC}"

    # Solicitar ID
    read -p "Ingresa el ID numérico de 3 dígitos [Presiona Enter para usar $SUGGESTED_ID]: " input_id
    ID=${input_id:-$SUGGESTED_ID}
    
    # Solicitar slug
    read -p "Ingresa el slug descriptivo en kebab-case (ej: login-seguro): " SLUG
fi

# Soporte para 'auto' o 'next' como segundo argumento en modo CLI
if [ "$ID" = "auto" ] || [ "$ID" = "next" ] || [ "$ID" = "AUTO" ] || [ "$ID" = "NEXT" ]; then
    MAX_FS_NUM=0
    for search_dir in "$PROJECT_ROOT/.ai/features" "$PROJECT_ROOT/.ai/archive"; do
        if [ -d "$search_dir" ]; then
            for folder in "$search_dir"/$TYPE-[0-9][0-9][0-9]*; do
                if [ -d "$folder" ]; then
                    bname=$(basename "$folder")
                    num_part=$(echo "$bname" | grep -oE "^$TYPE-[0-9]{3}" | cut -d'-' -f2 || true)
                    if [ -n "$num_part" ]; then
                        num_val=$((10#$num_part))
                        if [ $num_val -gt $MAX_FS_NUM ]; then
                            MAX_FS_NUM=$num_val
                        fi
                    fi
                fi
            done
        fi
    done

    MAX_CTX_NUM=0
    CONTEXT_FILE="$PROJECT_ROOT/.ai/context.md"
    if [ -f "$CONTEXT_FILE" ]; then
        LAST_ASSIGNED=$(grep -i "Último $TYPE asignado:" "$CONTEXT_FILE" | grep -oE "$TYPE-[0-9]+" | cut -d'-' -f2 || true)
        if [ -n "$LAST_ASSIGNED" ]; then
            MAX_CTX_NUM=$((10#$LAST_ASSIGNED))
        fi
    fi

    MAX_NUM=$(( MAX_FS_NUM > MAX_CTX_NUM ? MAX_FS_NUM : MAX_CTX_NUM ))
    NEXT_NUM=$(( MAX_NUM + 1 ))
    ID=$(printf "%03d" "$NEXT_NUM")
    echo -e "${GREEN}✓ ID asignado automáticamente: $ID${NC}"
fi

# 2. Validar formatos
if [[ ! " $INITIATIVE_TYPES " =~ " $TYPE " ]]; then
    echo -e "${RED}Error: El tipo debe ser uno de: $INITIATIVE_TYPES${NC}"
    exit 1
fi

if [[ ! "$ID" =~ ^[0-9]{3}$ ]]; then
    echo -e "${RED}Error: El ID debe ser un número de exactamente 3 dígitos (ej: 001, 023).${NC}"
    exit 1
fi

# Validar slug (solo minúsculas, números y guiones)
if [[ ! "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
    echo -e "${YELLOW}Advertencia: El slug debe estar en kebab-case (ej: mi-nueva-feature).${NC}"
    read -p "¿Deseas corregirlo automáticamente a kebab-case? (s/n): " fix_slug
    if [[ "$fix_slug" =~ ^[sS]$ ]]; then
        # Convertir a minúsculas, reemplazar espacios/subguiones por guiones, quitar caracteres especiales
        SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | sed 's/[_ ]/-/g' | sed 's/[^a-z0-9-]//g' | sed 's/-\{1,\}/-/g')
        echo -e "${GREEN}✓ Slug formateado a: $SLUG${NC}"
    else
        echo -e "${RED}Error: Slug inválido.${NC}"
        exit 1
    fi
fi

INITIATIVE_NAME="${TYPE}-${ID}-${SLUG}"
TARGET_DIR="$PROJECT_ROOT/.ai/features/$INITIATIVE_NAME"

# 3. Verificar si ya existe
if [ -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: El directorio de la iniciativa ya existe en: $TARGET_DIR${NC}"
    exit 1
fi

# 4. Crear carpetas
echo -e "\n${BLUE}Creando estructura para $INITIATIVE_NAME...${NC}"
mkdir -p "$TARGET_DIR"

# Compatibilidad de sed inplace entre macOS (Darwin) y Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi

# Origen de plantillas
TEMPLATES_DIR="$AI_AGENTS_ROOT/templates"

if [ "$TYPE" = "FEAT" ]; then
    # Copiar especificación inicial para Features
    [ -f "$TEMPLATES_DIR/feature-spec.md" ] && cp "$TEMPLATES_DIR/feature-spec.md" "$TARGET_DIR/spec.md"
    
    # Crear decision.md inicial
    cat << EOF > "$TARGET_DIR/decision.md"
# Registro de Decisiones - $INITIATIVE_NAME

Este documento registra las decisiones técnicas puntuales tomadas para esta feature.
Si una decisión aplica globalmente al sistema, debe ser promovida a .ai/decisions.md (ADR) al cerrar la feature.

## Decisiones Locales
- Ninguna decisión registrada aún.
EOF

    # Reemplazar placeholders en los archivos copiados
    for f in "$TARGET_DIR"/spec.md; do
        if [ -f "$f" ]; then
            "${SED_INPLACE[@]}" "s/FEAT-XXX/$TYPE-$ID/g" "$f"
            "${SED_INPLACE[@]}" "s/\[nombre\]/$SLUG/g" "$f"
        fi
    done
    echo -e "${GREEN}✓ Creados archivos iniciales de feature: spec.md, decision.md${NC}"
    echo -e "${YELLOW}  (ui-design.md, architecture.md y qa.md serán creados por sus agentes respectivos en cada fase)${NC}"

elif [ "$TYPE" = "BUG" ]; then
    # Copiar reporte de bug inicial
    [ -f "$TEMPLATES_DIR/bug-report.md" ] && cp "$TEMPLATES_DIR/bug-report.md" "$TARGET_DIR/bug-report.md"
    
    # Reemplazar placeholders
    for f in "$TARGET_DIR"/bug-report.md; do
        if [ -f "$f" ]; then
            "${SED_INPLACE[@]}" "s/BUG-XXX/$TYPE-$ID/g" "$f"
            "${SED_INPLACE[@]}" "s/\[nombre\]/$SLUG/g" "$f"
        fi
    done
    echo -e "${GREEN}✓ Creado archivo inicial de bug: bug-report.md${NC}"
    echo -e "${YELLOW}  (qa.md será generado por el QA Engineer al verificar la solución)${NC}"

else
    # AUDIT y REF: estructura libre (README de inicio, sin template fijo)
    cat << EOF > "$TARGET_DIR/README.md"
# $INITIATIVE_NAME

> Iniciativa de tipo $TYPE con estructura libre (sin documentos obligatorios).
> Completa esta carpeta con los documentos que apliquen según el flujo
> (ej: auditoría, hallazgos, plan de remediación, decisiones, etc.) y
> registra los avances en .ai/memory/workflow-log.md.

## Alcance
- Pendiente de definir.

## Documentos internos
- README.md
EOF
    echo -e "${GREEN}✓ Creada estructura libre: README.md (tipo $TYPE).${NC}"
fi

# 5. Actualizar .ai/context.md
CONTEXT_FILE="$PROJECT_ROOT/.ai/context.md"
if [ -f "$CONTEXT_FILE" ]; then
    echo -e "\n${BLUE}Actualizando registro de IDs en .ai/context.md...${NC}"
    
    # Si no existe la sección ## Registro de IDs, añadirla al final
    if ! grep -q "## Registro de IDs" "$CONTEXT_FILE"; then
        cat << 'EOF' >> "$CONTEXT_FILE"

## Registro de IDs
- Último AUDIT asignado: AUDIT-000
- Último BUG asignado: BUG-000
- Último FEAT asignado: FEAT-000
- Último REF asignado: REF-000
- Último ARCH asignado: ARCH-000
EOF
        echo -e "${YELLOW}! Sección '## Registro de IDs' agregada al final de context.md${NC}"
    fi
    
    # Verificar valor previo para no degradar el ID si otra rama ya registró uno superior
    CURRENT_REG=$(grep -i "Último $TYPE asignado:" "$CONTEXT_FILE" | grep -oE "$TYPE-[0-9]+" | cut -d'-' -f2 || echo "000")
    if [ $((10#$ID)) -ge $((10#$CURRENT_REG)) ]; then
        "${SED_INPLACE[@]}" "s/- Último $TYPE asignado:.*/- Último $TYPE asignado: $TYPE-$ID/g" "$CONTEXT_FILE"
        echo -e "${GREEN}✓ Registrado $TYPE-$ID como el último asignado en context.md.${NC}"
    else
        echo -e "${YELLOW}! context.md ya tiene registrado un ID superior ($TYPE-$CURRENT_REG). No se modifica.${NC}"
    fi
else
    echo -e "${YELLOW}Advertencia: No se encontró el archivo .ai/context.md. No se pudo actualizar el registro de IDs.${NC}"
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   🎉 ¡Iniciativa $INITIATIVE_NAME inicializada!      ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Carpeta: ${YELLOW}.ai/features/$INITIATIVE_NAME/${NC}"
echo -e "Comienza tu flujo de trabajo instanciando los agentes recomendados."
echo -e "===================================================="
