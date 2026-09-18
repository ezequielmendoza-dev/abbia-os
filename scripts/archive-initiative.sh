#!/usr/bin/env bash

# ==============================================================================
# archive-initiative.sh — Abbia OS Initiative Archiver
# ==============================================================================
# Archiva de forma segura y controlada una iniciativa (FEAT/BUG/AUDIT/REF):
#   1. Valida que exista en initiatives/ y que QA esté APROBADO (gate de calidad).
#   2. Mueve la carpeta a archive/ manteniendo su nombre canónico.
#   3. Actualiza referencias de archivos en knowledge-graph.yaml.
#   4. Registra el evento de archivado en memory/workflow-log.md.
#   5. Regenera memory/context-snapshot.md.
#
# Uso:
#   bash archive-initiative.sh <INICIATIVA> [OPCIONES]
#   Ej:  bash archive-initiative.sh FEAT-113
#        bash archive-initiative.sh BUG-075-actualizacion-servicios
#        bash archive-initiative.sh FEAT-113 --force
#        bash archive-initiative.sh FEAT-113 --note "Deployado en v4.0.0"
#        ./abbia archive FEAT-113
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
echo -e "${CYAN}   📦 Archivado de Iniciativa (Abbia OS v4.0.0)     ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Proyecto: ${YELLOW}$PROJECT_ROOT${NC}"

INITIATIVE="${1:-}"
FORCE=false
PROMPT=false
NOTE=""
NO_SNAPSHOT=false

if [ -z "$INITIATIVE" ] || [[ "$INITIATIVE" == -* ]]; then
    echo -e "${RED}Error: Se requiere el identificador o nombre de la iniciativa.${NC}"
    echo -e "Uso: bash archive-initiative.sh <INICIATIVA> [OPCIONES]"
    exit 1
fi

shift || true
while [ $# -gt 0 ]; do
    case "$1" in
        --force)       FORCE=true; shift ;;
        --prompt)      PROMPT=true; shift ;;
        --note)        NOTE="${2:-}"; shift 2 ;;
        --no-snapshot) NO_SNAPSHOT=true; shift ;;
        -*) echo -e "${RED}Error: Opción desconocida '$1'.${NC}"; exit 1 ;;
        *) shift ;;
    esac
done

if [ ! -d "$ABBIA_INITIATIVES_DIR" ]; then
    echo -e "${RED}Error: No existe el directorio de iniciativas en $ABBIA_INITIATIVES_DIR.${NC}"
    exit 1
fi

mkdir -p "$ABBIA_ARCHIVE_DIR"

SRC_DIR=""
if [ -d "$ABBIA_INITIATIVES_DIR/$INITIATIVE" ]; then
    SRC_DIR="$ABBIA_INITIATIVES_DIR/$INITIATIVE"
else
    shopt -s nullglob
    matches=()
    for d in "$ABBIA_INITIATIVES_DIR/$INITIATIVE" "$ABBIA_INITIATIVES_DIR/$INITIATIVE"-*; do
        if [ -d "$d" ]; then
            matches+=("$d")
        fi
    done
    shopt -u nullglob
    if [ ${#matches[@]} -eq 1 ]; then
        SRC_DIR="${matches[0]}"
    elif [ ${#matches[@]} -gt 1 ]; then
        echo -e "${RED}Error: Coincidencias múltiples para '$INITIATIVE':${NC}"
        for m in "${matches[@]}"; do
            echo "  - $(basename "$m")"
        done
        echo "Por favor especifica el nombre completo de la carpeta."
        exit 1
    fi
fi

if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR" ]; then
    if [ -d "$ABBIA_ARCHIVE_DIR/$INITIATIVE" ]; then
        echo -e "${YELLOW}ℹ️  La iniciativa '$INITIATIVE' ya se encuentra archivada en ${ABBIA_ARCHIVE_DIR#$PROJECT_ROOT/}.${NC}"
        exit 0
    fi
    echo -e "${RED}Error: No se encontró la iniciativa '$INITIATIVE' en ${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}.${NC}"
    exit 1
fi

FOLDER_NAME="$(basename "$SRC_DIR")"
TYPE=$(echo "$FOLDER_NAME" | cut -d'-' -f1)
NUM=$(echo "$FOLDER_NAME" | cut -d'-' -f2)
INITIATIVE_ID="$TYPE-$NUM"

# Validar QA
QA_FILE="$SRC_DIR/qa.md"
QA_VERDICT="NO_DECLARADO"

if [ -f "$QA_FILE" ]; then
    if grep -iqE '(veredicto|estado|resultado)\*{0,2}[[:space:]]*[:—–-][^A-Za-z0-9]*(APROBADO|PASS)' "$QA_FILE" || \
       grep -iqE '###[[:space:]]*Veredicto.*(APROBADO|PASS)' "$QA_FILE"; then
        QA_VERDICT="APROBADO"
    elif grep -iqE '(veredicto|estado|resultado)\*{0,2}[[:space:]]*[:—–-][^A-Za-z0-9]*(RECHAZADO|FAIL)' "$QA_FILE" || \
          grep -iqE '###[[:space:]]*Veredicto.*(RECHAZADO|FAIL)' "$QA_FILE"; then
        QA_VERDICT="RECHAZADO"
    fi
fi

if [ "$QA_VERDICT" != "APROBADO" ]; then
    if [ "$FORCE" = false ]; then
        echo -e "${RED}❌ Bloqueo de Calidad: La iniciativa '$FOLDER_NAME' no tiene QA APROBADO.${NC}"
        echo -e "   Estado detectado en qa.md: ${YELLOW}$QA_VERDICT${NC}"
        echo -e "   Para archivarla bajo tu responsabilidad, usa el flag ${YELLOW}--force${NC}."
        exit 1
    else
        echo -e "${YELLOW}⚠️  Advertencia: Forzando archivado con estado de QA '$QA_VERDICT' (--force activado).${NC}"
    fi
else
    echo -e "${GREEN}✓ QA verificado: APROBADO${NC}"
fi

# Confirmación interactiva
if [ "$PROMPT" = true ]; then
    echo -e "\n${YELLOW}¿Confirmas archivar '$FOLDER_NAME' y moverla a ${ABBIA_ARCHIVE_DIR#$PROJECT_ROOT/}? (s/N):${NC} "
    read -r resp
    if [[ ! "$resp" =~ ^[sSyY]$ ]]; then
        echo -e "Operación cancelada por el usuario."
        exit 0
    fi
fi

DEST_DIR="$ABBIA_ARCHIVE_DIR/$FOLDER_NAME"
if [ -d "$DEST_DIR" ]; then
    echo -e "${YELLOW}⚠️  El destino '$DEST_DIR' ya existía. Sobrescribiendo...${NC}"
    rm -rf "$DEST_DIR"
fi

mv "$SRC_DIR" "$DEST_DIR"
echo -e "${GREEN}✓ Carpeta movida:${NC} ${ABBIA_INITIATIVES_DIR#$PROJECT_ROOT/}/$FOLDER_NAME ➔ ${YELLOW}${ABBIA_ARCHIVE_DIR#$PROJECT_ROOT/}/$FOLDER_NAME${NC}"

# Actualizar references en knowledge-graph.yaml
KG_FILE="$ABBIA_DIR/knowledge-graph.yaml"
if [ -f "$KG_FILE" ]; then
    if grep -q "initiatives/$FOLDER_NAME" "$KG_FILE" || grep -q "features/$FOLDER_NAME" "$KG_FILE"; then
        sed -i.bak "s|initiatives/$FOLDER_NAME|archive/$FOLDER_NAME|g" "$KG_FILE" 2>/dev/null || \
        sed -i '' "s|initiatives/$FOLDER_NAME|archive/$FOLDER_NAME|g" "$KG_FILE" 2>/dev/null || true
        sed -i.bak "s|features/$FOLDER_NAME|archive/$FOLDER_NAME|g" "$KG_FILE" 2>/dev/null || \
        sed -i '' "s|features/$FOLDER_NAME|archive/$FOLDER_NAME|g" "$KG_FILE" 2>/dev/null || true
        rm -f "$KG_FILE.bak"
        echo -e "${GREEN}✓ Referencias actualizadas en knowledge-graph.yaml${NC}"
    fi
fi

# Registrar en workflow-log.md
LOG_FILE="$ABBIA_MEMORY_DIR/workflow-log.md"
CURRENT_DATE=$(date -u +"%Y-%m-%d")

if [ -f "$LOG_FILE" ]; then
    FINAL_NOTE="Iniciativa completada, validada y archivada tras paso a producción."
    if [ -n "$NOTE" ]; then
        FINAL_NOTE="$NOTE"
    fi

    cat << EOF >> "$LOG_FILE"

## [$INITIATIVE_ID] — $FOLDER_NAME
- **Fase:** release
- **Rol:** devops
- **Fecha:** $CURRENT_DATE
- **Modo:** estandar
- **Resultado:** APROBADO (Archivada en ${ABBIA_ARCHIVE_DIR#$PROJECT_ROOT/})
- **Nota:** $FINAL_NOTE
EOF
    echo -e "${GREEN}✓ Registrado cierre en workflow-log.md${NC}"
fi

if [ "$NO_SNAPSHOT" = false ]; then
    regenerate_context_snapshot "$PROJECT_ROOT"
    echo -e "${GREEN}✓ Regenerado context-snapshot.md${NC}"
fi

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}✨ Iniciativa '$FOLDER_NAME' archivada exitosamente en Abbia OS.${NC}"
echo -e "${GREEN}====================================================${NC}"
