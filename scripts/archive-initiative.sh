#!/usr/bin/env bash

# ==============================================================================
# archive-initiative.sh — ai-agents Initiative Archiver
# ==============================================================================
# Archiva de forma segura y controlada una iniciativa (FEAT/BUG/AUDIT/REF):
#   1. Valida que exista en .ai/features/ y que QA esté APROBADO (gate de calidad).
#   2. Mueve la carpeta a .ai/archive/ manteniendo su nombre canónico.
#   3. Actualiza referencias de archivos en .ai/knowledge-graph.yaml.
#   4. Registra el evento de archivado en .ai/memory/workflow-log.md.
#   5. Regenera .ai/memory/context-snapshot.md.
#
# Uso:
#   bash archive-initiative.sh <INICIATIVA> [OPCIONES]
#   Ej:  bash archive-initiative.sh FEAT-113
#        bash archive-initiative.sh BUG-075-actualizacion-grupos-servicios
#        bash archive-initiative.sh FEAT-113 --force
#        bash archive-initiative.sh FEAT-113 --note "Deployado en v3.2.0"
#
# Opciones:
#   --force        Ignora advertencias de QA o artefactos incompletos
#   --prompt       Solicita confirmación interactiva en terminal antes de archivar
#   --note "..."   Nota o resumen del pase a producción para el workflow-log
#   --no-snapshot  No regenerar context-snapshot (útil en procesos por lotes)
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
echo -e "${BLUE}   📦 Archivado de Iniciativa (ai-agents OS)       ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Proyecto: ${YELLOW}$PROJECT_ROOT${NC}"

# ---------- 1. Parsear argumentos ----------
INITIATIVE="${1:-}"
FORCE=false
PROMPT=false
NOTE=""
NO_SNAPSHOT=false

if [ -z "$INITIATIVE" ] || [[ "$INITIATIVE" == -* ]]; then
    echo -e "${RED}Error: Se requiere el identificador o nombre de la iniciativa.${NC}"
    echo -e "Uso: bash archive-initiative.sh <INICIATIVA> [OPCIONES]"
    echo -e "  ej: bash archive-initiative.sh FEAT-113"
    echo -e "      bash archive-initiative.sh BUG-075-actualizacion-grupos-servicios --note \"En producción\""
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

# ---------- 2. Localizar directorio origen en .ai/features/ ----------
FEATURES_DIR="$PROJECT_ROOT/.ai/features"
ARCHIVE_DIR="$PROJECT_ROOT/.ai/archive"

if [ ! -d "$FEATURES_DIR" ]; then
    echo -e "${RED}Error: No existe el directorio .ai/features/ en $PROJECT_ROOT.${NC}"
    exit 1
fi

mkdir -p "$ARCHIVE_DIR"

SRC_DIR=""
if [ -d "$FEATURES_DIR/$INITIATIVE" ]; then
    SRC_DIR="$FEATURES_DIR/$INITIATIVE"
else
    # Buscar por prefijo (ej. FEAT-113 -> FEAT-113-slug)
    shopt -s nullglob
    matches=()
    for d in "$FEATURES_DIR/$INITIATIVE" "$FEATURES_DIR/$INITIATIVE"-*; do
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
    # Verificar si ya estaba archivada
    if [ -d "$ARCHIVE_DIR/$INITIATIVE" ]; then
        echo -e "${YELLOW}ℹ️  La iniciativa '$INITIATIVE' ya se encuentra archivada en .ai/archive/.${NC}"
        exit 0
    fi
    echo -e "${RED}Error: No se encontró la iniciativa '$INITIATIVE' en .ai/features/.${NC}"
    exit 1
fi

FOLDER_NAME="$(basename "$SRC_DIR")"
TYPE=$(echo "$FOLDER_NAME" | cut -d'-' -f1)
NUM=$(echo "$FOLDER_NAME" | cut -d'-' -f2)
INITIATIVE_ID="$TYPE-$NUM"

# ---------- 3. Validar estado de QA y Gate de Calidad ----------
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
        echo -e "   Para archivarla igualmente bajo tu responsabilidad, usa el flag ${YELLOW}--force${NC}."
        exit 1
    else
        echo -e "${YELLOW}⚠️  Advertencia: Forzando archivado con estado de QA '$QA_VERDICT' (--force activado).${NC}"
    fi
else
    echo -e "${GREEN}✓ QA verificado: APROBADO${NC}"
fi

# ---------- 4. Confirmación Interactiva (si aplica) ----------
if [ "$PROMPT" = true ]; then
    echo -e "\n${YELLOW}¿Confirmas archivar '$FOLDER_NAME' y moverla a .ai/archive/? (s/N):${NC} "
    read -r resp
    if [[ ! "$resp" =~ ^[sSyY]$ ]]; then
        echo -e "Operación cancelada por el usuario."
        exit 0
    fi
fi

# ---------- 5. Mover carpeta a .ai/archive/ ----------
DEST_DIR="$ARCHIVE_DIR/$FOLDER_NAME"
if [ -d "$DEST_DIR" ]; then
    echo -e "${YELLOW}⚠️  El destino '$DEST_DIR' ya existía. Sobrescribiendo...${NC}"
    rm -rf "$DEST_DIR"
fi

mv "$SRC_DIR" "$DEST_DIR"
echo -e "${GREEN}✓ Carpeta movida:${NC} .ai/features/$FOLDER_NAME ➔ ${YELLOW}.ai/archive/$FOLDER_NAME${NC}"

# ---------- 6. Actualizar referencias en .ai/knowledge-graph.yaml ----------
KG_FILE="$PROJECT_ROOT/.ai/knowledge-graph.yaml"
if [ -f "$KG_FILE" ]; then
    if grep -q "features/$FOLDER_NAME" "$KG_FILE"; then
        sed -i.bak "s|features/$FOLDER_NAME|archive/$FOLDER_NAME|g" "$KG_FILE" 2>/dev/null || \
        sed -i '' "s|features/$FOLDER_NAME|archive/$FOLDER_NAME|g" "$KG_FILE" 2>/dev/null || true
        rm -f "$KG_FILE.bak"
        echo -e "${GREEN}✓ Referencias actualizadas en .ai/knowledge-graph.yaml${NC}"
    fi
fi

# ---------- 7. Registrar en .ai/memory/workflow-log.md ----------
MEM_DIR="$PROJECT_ROOT/.ai/memory"
LOG_FILE="$MEM_DIR/workflow-log.md"
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
- **Resultado:** APROBADO (Archivada en .ai/archive/)
- **Nota:** $FINAL_NOTE
EOF
    echo -e "${GREEN}✓ Registrado cierre en .ai/memory/workflow-log.md${NC}"
fi

# ---------- 8. Regenerar context-snapshot.md ----------
if [ "$NO_SNAPSHOT" = false ]; then
    regenerate_context_snapshot "$PROJECT_ROOT"
    echo -e "${GREEN}✓ Regenerado .ai/memory/context-snapshot.md${NC}"
fi

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}✨ Iniciativa '$FOLDER_NAME' archivada exitosamente.${NC}"
echo -e "${GREEN}====================================================${NC}"
