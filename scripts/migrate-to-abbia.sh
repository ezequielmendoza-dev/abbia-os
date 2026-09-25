#!/usr/bin/env bash

# ==============================================================================
# migrate-to-abbia.sh — Abbia OS v4.0.0 Migration Tool
# ==============================================================================
# Migra de forma segura e integral un proyecto existente que utiliza la estructura
# legacy (.ai/ o .stratum/) a la identidad canónica de Abbia OS (.abbia/ y .abbia/core).
#
# Acciones que realiza:
#   1. Renombra .ai/ o .stratum/ -> .abbia/ preservando historial e iniciativas.
#   2. Renombra features/ -> initiatives/ (o mantiene alias).
#   3. Actualiza .gitmodules (.ai/agents o .stratum/core -> .abbia/core).
#   4. Actualiza reglas de .gitignore y .gitattributes (.ai/ o .stratum/ -> .abbia/).
#   5. Instala/actualiza el CLI wrapper ./abbia.
#   6. Regenera configuraciones de IDEs (AGENTS.md, CLAUDE.md, .cursorrules, etc.).
#   7. Reconcilia snapshot de memoria y valida integridad final.
#
# Uso:
#   bash .abbia/core/scripts/migrate-to-abbia.sh
#   o desde legacy: bash .ai/agents/scripts/migrate-to-abbia.sh
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

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}     🚀 Herramienta de Migración a Abbia OS v4.0    ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Raíz del proyecto: ${YELLOW}$PROJECT_ROOT${NC}\n"

if [ ! -d "$PROJECT_ROOT/.ai" ] && [ ! -d "$PROJECT_ROOT/.stratum" ] && [ -d "$PROJECT_ROOT/.abbia" ]; then
    echo -e "${GREEN}✓ El proyecto ya se encuentra en la estructura canónica de Abbia OS (.abbia/).${NC}"
    echo -e "Ejecutando validación de consistencia..."
    bash "$SCRIPT_DIR/validate-project.sh"
    exit 0
fi

SRC_DIR=""
if [ -d "$PROJECT_ROOT/.stratum" ]; then
    SRC_DIR="$PROJECT_ROOT/.stratum"
elif [ -d "$PROJECT_ROOT/.ai" ]; then
    SRC_DIR="$PROJECT_ROOT/.ai"
else
    echo -e "${RED}Error: No se detectó ninguna estructura .ai/ o .stratum/ para migrar en $PROJECT_ROOT.${NC}"
    echo "Si deseas inicializar un nuevo proyecto con Abbia OS, ejecuta: bash setup-ide.sh"
    exit 1
fi

echo -e "${YELLOW}Se migrará la estructura de $(basename "$SRC_DIR")/ a .abbia/ manteniendo intactos todos tus artefactos.${NC}"

# Paso 1: Crear .abbia/ y mover contenido
echo -e "\n${BLUE}--- Paso 1: Migración de Directorios y Artefactos ---${NC}"
mkdir -p "$PROJECT_ROOT/.abbia"

# Mover archivos de configuración base
for f in context.md business-rules.md architecture.md decisions.md glossary.md knowledge-graph.yaml; do
    if [ -f "$SRC_DIR/$f" ] && [ ! -f "$PROJECT_ROOT/.abbia/$f" ]; then
        mv "$SRC_DIR/$f" "$PROJECT_ROOT/.abbia/$f"
        echo -e "  ${GREEN}✓${NC} Migrado: $(basename "$SRC_DIR")/$f -> .abbia/$f"
    fi
done

# Mover carpetas principales
for folder in memory metrics archive sessions; do
    if [ -d "$SRC_DIR/$folder" ] && [ ! -d "$PROJECT_ROOT/.abbia/$folder" ]; then
        mv "$SRC_DIR/$folder" "$PROJECT_ROOT/.abbia/$folder"
        echo -e "  ${GREEN}✓${NC} Migrado: $(basename "$SRC_DIR")/$folder -> .abbia/$folder"
    fi
done

# Mover features o initiatives
if [ -d "$SRC_DIR/initiatives" ] && [ ! -d "$PROJECT_ROOT/.abbia/initiatives" ]; then
    mv "$SRC_DIR/initiatives" "$PROJECT_ROOT/.abbia/initiatives"
    echo -e "  ${GREEN}✓${NC} Migrado: $(basename "$SRC_DIR")/initiatives -> .abbia/initiatives"
elif [ -d "$SRC_DIR/features" ] && [ ! -d "$PROJECT_ROOT/.abbia/initiatives" ]; then
    mv "$SRC_DIR/features" "$PROJECT_ROOT/.abbia/initiatives"
    echo -e "  ${GREEN}✓${NC} Migrado: $(basename "$SRC_DIR")/features -> .abbia/initiatives"
fi

# Paso 2: Submódulo Git
echo -e "\n${BLUE}--- Paso 2: Actualización del Submódulo Git ---${NC}"
if [ -f "$PROJECT_ROOT/.gitmodules" ]; then
    if grep -q "\.ai/agents\|\.stratum/core" "$PROJECT_ROOT/.gitmodules"; then
        echo -e "Actualizando ruta de submódulo en .gitmodules -> .abbia/core..."
        sed -i.bak -E 's|\.ai/agents|\.abbia/core|g; s|\.stratum/core|\.abbia/core|g' "$PROJECT_ROOT/.gitmodules" && rm -f "$PROJECT_ROOT/.gitmodules.bak"
    fi
    if grep -q "ai-agents\.git" "$PROJECT_ROOT/.gitmodules"; then
        echo -e "Actualizando URL del repositorio en .gitmodules -> abbia-os.git..."
        sed -i.bak -E 's|ai-agents\.git|abbia-os.git|g' "$PROJECT_ROOT/.gitmodules" && rm -f "$PROJECT_ROOT/.gitmodules.bak"
    fi
fi

if [ -d "$PROJECT_ROOT/.stratum/core" ] && [ ! -d "$PROJECT_ROOT/.abbia/core" ]; then
    mv "$PROJECT_ROOT/.stratum/core" "$PROJECT_ROOT/.abbia/core"
    echo -e "  ${GREEN}✓${NC} Movido submódulo/directorio .stratum/core a .abbia/core"
elif [ -d "$PROJECT_ROOT/.ai/agents" ] && [ ! -d "$PROJECT_ROOT/.abbia/core" ]; then
    mv "$PROJECT_ROOT/.ai/agents" "$PROJECT_ROOT/.abbia/core"
    echo -e "  ${GREEN}✓${NC} Movido submódulo/directorio .ai/agents a .abbia/core"
fi

# Sincronizar git submodule si estamos en un repo git
if [ -d "$PROJECT_ROOT/.git" ] && [ -f "$PROJECT_ROOT/.gitmodules" ]; then
    (cd "$PROJECT_ROOT" && git submodule sync 2>/dev/null || true)
fi

# Limpiar directorio origen residual
if [ -d "$SRC_DIR" ]; then
    rm -rf "$SRC_DIR/dashboard.html" 2>/dev/null || true
    rm -rf "$SRC_DIR/agents" 2>/dev/null || true
    rm -rf "$SRC_DIR/core" 2>/dev/null || true
    rmdir "$SRC_DIR" 2>/dev/null || true
    if [ -d "$SRC_DIR" ]; then
        echo -e "${YELLOW}! Nota: Quedaron elementos residuales en $(basename "$SRC_DIR")/. Por favor revísalos manualmente.${NC}"
    else
        echo -e "  ${GREEN}✓${NC} Carpeta legacy $(basename "$SRC_DIR")/ eliminada limpiamente."
    fi
fi

# Paso 3: Actualizar .gitignore y .gitattributes
echo -e "\n${BLUE}--- Paso 3: Actualización de .gitignore y .gitattributes ---${NC}"
if [ -f "$PROJECT_ROOT/.gitignore" ]; then
    sed -i.bak -E 's|\.ai/|\.abbia/|g; s|\.stratum/|\.abbia/|g' "$PROJECT_ROOT/.gitignore" && rm -f "$PROJECT_ROOT/.gitignore.bak"
    echo -e "  ${GREEN}✓${NC} Actualizado .gitignore para .abbia/"
fi

if [ -f "$PROJECT_ROOT/.gitattributes" ]; then
    sed -i.bak -E 's|\.ai/|\.abbia/|g; s|\.stratum/|\.abbia/|g' "$PROJECT_ROOT/.gitattributes" && rm -f "$PROJECT_ROOT/.gitattributes.bak"
    echo -e "  ${GREEN}✓${NC} Actualizado .gitattributes para .abbia/"
fi

# Paso 4: Regenerar reglas de IDE y wrapper CLI
echo -e "\n${BLUE}--- Paso 4: Regenerando Reglas de IDEs y CLI Wrapper ---${NC}"
resolve_abbia_paths "$PROJECT_ROOT"
bash "$SCRIPT_DIR/setup-ide.sh" --auto

# Actualizar/instalar templates de IDEs para Abbia OS
IDE_TEMPLATES_DIR="$ABBIA_CORE_ROOT/templates/ide-configs"
if [ -d "$IDE_TEMPLATES_DIR" ]; then
    [ -f "$PROJECT_ROOT/.cursorrules" ] && cp "$IDE_TEMPLATES_DIR/cursorrules" "$PROJECT_ROOT/.cursorrules" && echo -e "  ${GREEN}✓${NC} Actualizado .cursorrules"
    [ -f "$PROJECT_ROOT/CLAUDE.md" ] && cp "$IDE_TEMPLATES_DIR/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md" && echo -e "  ${GREEN}✓${NC} Actualizado CLAUDE.md"
    [ -f "$PROJECT_ROOT/.windsurfrules" ] && cp "$IDE_TEMPLATES_DIR/windsurfrules" "$PROJECT_ROOT/.windsurfrules" && echo -e "  ${GREEN}✓${NC} Actualizado .windsurfrules"
    [ -f "$PROJECT_ROOT/.clinerules" ] && cp "$IDE_TEMPLATES_DIR/clinerules" "$PROJECT_ROOT/.clinerules" && echo -e "  ${GREEN}✓${NC} Actualizado .clinerules"
    [ -f "$PROJECT_ROOT/AGENTS.md" ] && cp "$IDE_TEMPLATES_DIR/AGENTS.md" "$PROJECT_ROOT/AGENTS.md" && echo -e "  ${GREEN}✓${NC} Actualizado AGENTS.md"
    if [ -d "$PROJECT_ROOT/.cursor/rules" ] && [ -d "$IDE_TEMPLATES_DIR/cursor-rules" ]; then
        cp -r "$IDE_TEMPLATES_DIR/cursor-rules/"* "$PROJECT_ROOT/.cursor/rules/"
        echo -e "  ${GREEN}✓${NC} Actualizadas reglas modulares de Cursor (.cursor/rules/*.mdc)"
    fi
    if [ -f "$PROJECT_ROOT/.github/copilot-instructions.md" ]; then
        cp "$IDE_TEMPLATES_DIR/copilot-instructions.md" "$PROJECT_ROOT/.github/copilot-instructions.md"
        echo -e "  ${GREEN}✓${NC} Actualizado .github/copilot-instructions.md"
    fi
fi

# Paso 5: Reconciliación de Memoria y Snapshot
echo -e "\n${BLUE}--- Paso 5: Reconciliando Memoria Técnica Abbia ---${NC}"
regenerate_context_snapshot "$PROJECT_ROOT"
echo -e "  ${GREEN}✓${NC} Snapshot de contexto regenerado en .abbia/memory/context-snapshot.md"

# Paso 6: Validación final
echo -e "\n${BLUE}--- Paso 6: Validación Final de Integridad ---${NC}"
bash "$SCRIPT_DIR/validate-project.sh"

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${GREEN}🎉 ¡Migración a Abbia OS v4.0.0 completada con éxito!${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Tus iniciativas y memoria técnica ahora viven en ${YELLOW}.abbia/${NC}."
echo -e "Puedes abrir el nuevo dashboard con: ${GREEN}./abbia dashboard${NC} o ${GREEN}bash .abbia/core/scripts/dashboard.sh${NC}\n"
