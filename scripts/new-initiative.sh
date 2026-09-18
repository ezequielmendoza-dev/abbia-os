#!/usr/bin/env bash

# ==============================================================================
# new-initiative.sh — Abbia OS Initiative Bootstrapper
# ==============================================================================
# Automatiza el bootstrap de una nueva iniciativa (feature, bug, auditoría o
# refactor) en la carpeta de iniciativas (.abbia/initiatives/) y actualiza el
# registro de IDs en context.md.
# Tipos soportados: FEAT (feature), BUG (bug), AUDIT (auditoría/seguridad),
# REF (refactor).
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
echo -e "${CYAN}     🚀 Generador de Iniciativas (Abbia OS v4.0)    ${NC}"
echo -e "${CYAN}====================================================${NC}"

if [ ! -d "$ABBIA_DIR" ]; then
    echo -e "${RED}Error: No se encontró la carpeta de configuración ($ABBIA_DIR) en: $PROJECT_ROOT${NC}"
    echo -e "Ejecuta primero: bash setup-ide.sh"
    exit 1
fi

TYPE=""
ID=""
SLUG=""

if [ "$#" -ge 3 ]; then
    TYPE=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    ID="$2"
    SLUG="$3"
else
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
    
    # Determinar siguiente ID dinámicamente
    MAX_FS_NUM=0
    for search_dir in "$ABBIA_INITIATIVES_DIR" "$ABBIA_ARCHIVE_DIR"; do
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
    CONTEXT_FILE="$ABBIA_DIR/context.md"
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

    read -p "Ingresa el ID numérico de 3 dígitos [Presiona Enter para usar $SUGGESTED_ID]: " input_id
    ID=${input_id:-$SUGGESTED_ID}
    
    read -p "Ingresa el slug descriptivo en kebab-case (ej: login-mfa): " SLUG
fi

if [ "$ID" = "auto" ] || [ "$ID" = "next" ] || [ "$ID" = "AUTO" ] || [ "$ID" = "NEXT" ]; then
    MAX_FS_NUM=0
    for search_dir in "$ABBIA_INITIATIVES_DIR" "$ABBIA_ARCHIVE_DIR"; do
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
    CONTEXT_FILE="$ABBIA_DIR/context.md"
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

if [[ ! " $INITIATIVE_TYPES " =~ " $TYPE " ]]; then
    echo -e "${RED}Error: El tipo debe ser uno de: $INITIATIVE_TYPES${NC}"
    exit 1
fi

if [[ ! "$ID" =~ ^[0-9]{3}$ ]]; then
    echo -e "${RED}Error: El ID debe ser un número de exactamente 3 dígitos (ej: 001, 023).${NC}"
    exit 1
fi

if [[ ! "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
    echo -e "${YELLOW}Advertencia: El slug debe estar en kebab-case (ej: mi-nueva-feature).${NC}"
    read -p "¿Deseas corregirlo automáticamente a kebab-case? (s/n): " fix_slug
    if [[ "$fix_slug" =~ ^[sS]$ ]]; then
        SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | sed 's/[_ ]/-/g' | sed 's/[^a-z0-9-]//g' | sed 's/-\{1,\}/-/g')
        echo -e "${GREEN}✓ Slug formateado a: $SLUG${NC}"
    else
        echo -e "${RED}Error: Slug inválido.${NC}"
        exit 1
    fi
fi

INITIATIVE_NAME="${TYPE}-${ID}-${SLUG}"
TARGET_DIR="$ABBIA_INITIATIVES_DIR/$INITIATIVE_NAME"

if [ -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: El directorio de la iniciativa ya existe en: $TARGET_DIR${NC}"
    exit 1
fi

echo -e "\n${BLUE}Creando estructura para $INITIATIVE_NAME en ${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}...${NC}"
mkdir -p "$TARGET_DIR"

if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi

TEMPLATES_DIR="$ABBIA_CORE_ROOT/templates"

if [ "$TYPE" = "FEAT" ]; then
    [ -f "$TEMPLATES_DIR/feature-spec.md" ] && cp "$TEMPLATES_DIR/feature-spec.md" "$TARGET_DIR/spec.md"
    
    cat << EOF > "$TARGET_DIR/decision.md"
# Registro de Decisiones - $INITIATIVE_NAME

Este documento registra las decisiones técnicas puntuales tomadas para esta feature en Abbia OS.
Si una decisión aplica globalmente al sistema, debe ser promovida a ${ABBIA_DIR#$PROJECT_ROOT/}/knowledge-graph.yaml (ADR) al cerrar la feature.

## Decisiones Locales
- Ninguna decisión registrada aún.
EOF

    for f in "$TARGET_DIR"/spec.md; do
        if [ -f "$f" ]; then
            "${SED_INPLACE[@]}" "s/FEAT-XXX/$TYPE-$ID/g" "$f"
            "${SED_INPLACE[@]}" "s/\[nombre\]/$SLUG/g" "$f"
        fi
    done
    echo -e "${GREEN}✓ Creados archivos iniciales de feature: spec.md, decision.md${NC}"
    echo -e "${YELLOW}  (ui-design.md, architecture.md y qa.md serán creados por sus agentes respectivos en cada fase)${NC}"

elif [ "$TYPE" = "BUG" ]; then
    [ -f "$TEMPLATES_DIR/bug-report.md" ] && cp "$TEMPLATES_DIR/bug-report.md" "$TARGET_DIR/bug-report.md"
    
    for f in "$TARGET_DIR"/bug-report.md; do
        if [ -f "$f" ]; then
            "${SED_INPLACE[@]}" "s/BUG-XXX/$TYPE-$ID/g" "$f"
            "${SED_INPLACE[@]}" "s/\[nombre\]/$SLUG/g" "$f"
        fi
    done
    echo -e "${GREEN}✓ Creado archivo inicial de bug: bug-report.md${NC}"
    echo -e "${YELLOW}  (qa.md será generado por el QA Engineer al verificar la solución)${NC}"

else
    cat << EOF > "$TARGET_DIR/README.md"
# $INITIATIVE_NAME

> Iniciativa de tipo $TYPE con estructura libre en Abbia OS.
> Completa esta carpeta con los documentos que apliquen según el flujo
> y registra los avances en ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/workflow-log.md.

## Alcance
- Pendiente de definir.

## Documentos internos
- README.md
EOF
    echo -e "${GREEN}✓ Creada estructura libre: README.md (tipo $TYPE).${NC}"
fi

CONTEXT_FILE="$ABBIA_DIR/context.md"
if [ -f "$CONTEXT_FILE" ]; then
    echo -e "\n${BLUE}Actualizando registro de IDs en ${ABBIA_DIR#$PROJECT_ROOT/}/context.md...${NC}"
    
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
    
    CURRENT_REG=$(grep -i "Último $TYPE asignado:" "$CONTEXT_FILE" | grep -oE "$TYPE-[0-9]+" | cut -d'-' -f2 || echo "000")
    if [ $((10#$ID)) -ge $((10#$CURRENT_REG)) ]; then
        "${SED_INPLACE[@]}" "s/- Último $TYPE asignado:.*/- Último $TYPE asignado: $TYPE-$ID/g" "$CONTEXT_FILE"
        echo -e "${GREEN}✓ Registrado $TYPE-$ID como el último asignado en context.md.${NC}"
    else
        echo -e "${YELLOW}! context.md ya tiene registrado un ID superior ($TYPE-$CURRENT_REG). No se modifica.${NC}"
    fi
else
    echo -e "${YELLOW}Advertencia: No se encontró el archivo ${ABBIA_DIR#$PROJECT_ROOT/}/context.md.${NC}"
fi

# Auto-actualizar dashboard si existe
auto_refresh_dashboard_if_exists "$PROJECT_ROOT"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}     🎉 ¡Iniciativa $INITIATIVE_NAME inicializada!    ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Carpeta: ${YELLOW}${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}/$INITIATIVE_NAME/${NC}"
echo -e "Comienza tu flujo de trabajo ejecutando los agentes de Abbia OS."
echo -e "===================================================="

