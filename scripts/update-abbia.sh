#!/usr/bin/env bash

# ==============================================================================
# update-abbia.sh — Abbia OS Framework Updater
# ==============================================================================
# Actualiza el submódulo de Abbia OS al commit/tag indicado (o al último),
# commitea el cambio en el proyecto, y ejecuta setup-ide.sh (idempotente)
# para aplicar las últimas capacidades y sincronizar las iniciativas.
#
# Uso:
#   bash .abbia/core/scripts/update-abbia.sh                 # último commit
#   bash .abbia/core/scripts/update-abbia.sh v4.0.0          # pin a un tag
#   ./abbia update [v4.0.0]
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo "Error: No se encontró common.sh en $SCRIPT_DIR"
    exit 1
fi

VERSION="${1:-}"

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}     🔄 Actualizador de Abbia OS (submodule)        ${NC}"
echo -e "${CYAN}====================================================${NC}"

PROJECT_ROOT="$(detect_project_root)"
resolve_abbia_paths "$PROJECT_ROOT"
echo -e "Proyecto detectado: ${YELLOW}$PROJECT_ROOT${NC}"

SUBMODULE_DIR="$ABBIA_CORE"
if [ ! -f "$SUBMODULE_DIR/.git" ] && [ ! -d "$SUBMODULE_DIR/.git" ]; then
    echo -e "${RED}Error: No se encontró el submódulo en $SUBMODULE_DIR${NC}"
    echo -e "${YELLOW}Si este es un proyecto nuevo, usa setup-ide.sh para inicializar.${NC}"
    exit 1
fi

if [ -n "$VERSION" ]; then
    echo -e "\n${BLUE}--- 1/4: Actualizando submódulo a $VERSION ---${NC}"
    (cd "$SUBMODULE_DIR" && git fetch --tags --quiet && git checkout -f -B "$VERSION" "$VERSION" && git reset --hard "$VERSION")
else
    echo -e "\n${BLUE}--- 1/4: Actualizando submódulo al último commit ---${NC}"
    (cd "$SUBMODULE_DIR" && git fetch --quiet && git checkout -f -B main origin/main && git reset --hard origin/main)
fi

NEW_VERSION="$(cd "$SUBMODULE_DIR" && git describe --tags --always 2>/dev/null || git rev-parse --short HEAD)"
echo -e "${GREEN}✓ Submódulo actualizado a: ${NEW_VERSION}${NC}"

echo -e "\n${BLUE}--- 2/4: Commiteando puntero del submódulo en el proyecto ---${NC}"
cd "$PROJECT_ROOT"
relative_submodule="${SUBMODULE_DIR#$PROJECT_ROOT/}"
git add "$relative_submodule"
if git diff --cached --quiet; then
    echo -e "${GREEN}! No hay cambios en el puntero del submódulo. Nada que commitear.${NC}"
else
    git commit -m "chore: update Abbia OS submodule to $NEW_VERSION"
    echo -e "${GREEN}✓ Puntero del submódulo commiteado (${NEW_VERSION}).${NC}"
fi

echo -e "\n${BLUE}--- 3/4: Ejecutando setup-ide.sh (sistemas Abbia v4) ---${NC}"
bash "$SUBMODULE_DIR/scripts/setup-ide.sh" --auto

echo -e "\n${BLUE}--- 4/4: Reconciliando iniciativas (sync-initiatives --fix) ---${NC}"
bash "$SUBMODULE_DIR/scripts/sync-initiatives.sh" --fix

echo -e "\n${BLUE}--- Verificación final de conformidad documental ---${NC}"
bash "$SUBMODULE_DIR/scripts/validate-project.sh"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}     🎉 Abbia OS actualizado a ${NEW_VERSION}!      ${NC}"
echo -e "${GREEN}====================================================${NC}"
