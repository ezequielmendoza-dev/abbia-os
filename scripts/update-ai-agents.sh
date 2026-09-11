#!/usr/bin/env bash

# ==============================================================================
# update-ai-agents.sh — ai-agents OS Updater (actualización en un solo comando)
# ==============================================================================
# Actualiza el submodule .ai/agents al commit/tag indicado (o al último),
# commitea el cambio en el proyecto, y ejecuta setup-ide.sh (idempotente)
# para crear/actualizar los seeds de los sistemas v3.x que falten.
# ==============================================================================
# Uso:
#   bash .ai/agents/scripts/update-ai-agents.sh                 # último commit
#   bash .ai/agents/scripts/update-ai-agents.sh v3.2.1          # pin a un tag
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

VERSION="${1:-}"

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🔄 Actualizador de ai-agents OS (submodule)       ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Determinar raíz del proyecto
PROJECT_ROOT="$(detect_project_root)"
echo -e "Proyecto detectado: ${YELLOW}$PROJECT_ROOT${NC}"

# 2. Verificar que .ai/agents es un submódulo
SUBMODULE_DIR="$PROJECT_ROOT/.ai/agents"
if [ ! -f "$SUBMODULE_DIR/.git" ] && [ ! -d "$SUBMODULE_DIR/.git" ]; then
    echo -e "${RED}Error: No se encontró el submódulo en $SUBMODULE_DIR${NC}"
    echo -e "${YELLOW}Si este es un proyecto nuevo, usa setup-ide.sh para inicializar.${NC}"
    exit 1
fi

if [ -n "$VERSION" ]; then
    # 3a. Pin a una versión específica (tag)
    echo -e "\n${BLUE}--- 1/3: Actualizando submodule a $VERSION ---${NC}"
    (cd "$SUBMODULE_DIR" && git fetch --tags --quiet && git checkout "$VERSION")
else
    # 3b. Último commit de la rama principal
    echo -e "\n${BLUE}--- 1/3: Actualizando submodule al último commit ---${NC}"
    (cd "$SUBMODULE_DIR" && git fetch --quiet && git checkout main && git pull --ff-only --quiet)
fi

NEW_VERSION="$(cd "$SUBMODULE_DIR" && git describe --tags --always 2>/dev/null || git rev-parse --short HEAD)"
echo -e "${GREEN}✓ Submodule actualizado a: ${NEW_VERSION}${NC}"

# 4. Commit del puntero del submódulo en el proyecto
echo -e "\n${BLUE}--- 2/3: Commiteando puntero del submódulo en el proyecto ---${NC}"
cd "$PROJECT_ROOT"
git add .ai/agents
if git diff --cached --quiet; then
    echo -e "${GREEN}! No hay cambios en el puntero del submódulo. Nada que commitear.${NC}"
else
    git commit -m "chore: update ai-agents submodule to $NEW_VERSION"
    echo -e "${GREEN}✓ Puntero del submódulo commiteado (${NEW_VERSION}).${NC}"
fi

# 5. Ejecutar setup-ide.sh para activar los nuevos sistemas (idempotente, no-interactivo)
echo -e "\n${BLUE}--- 3/3: Ejecutando setup-ide.sh (sistemas v3.x) ---${NC}"
bash "$SUBMODULE_DIR/scripts/setup-ide.sh" --auto

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   🎉 ai-agents OS actualizado a ${NEW_VERSION}!       ${NC}"
echo -e "${GREEN}====================================================${NC}"