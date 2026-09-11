#!/usr/bin/env bash

# ==============================================================================
# setup-ide.sh — ai-agents OS Installer
# ==============================================================================
# Este script inicializa la estructura .ai/ (incl. sistemas v3.x: memoria,
# métricas y knowledge graph) y genera los archivos de reglas para diferentes
# IDEs de IA en el proyecto donde se ejecuta.
# Uso:
#   bash setup-ide.sh             # interactivo
#   bash setup-ide.sh --auto      # no-interactivo (inicializa .ai/ y .gitignore;
#                                 #  no regenera reglas IDE; usado por update-ai-agents.sh)
# ==============================================================================

set -euo pipefail

# Modo no-interactivo: salta preguntas, inicializa .ai/ y no regenera reglas IDE.
# Uso: setup-ide.sh --auto   (usado por update-ai-agents.sh)
AUTO_MODE=false
if [ "${1:-}" = "--auto" ]; then
    AUTO_MODE=true
fi

# Determinar directorio del script e importar utilidades comunes
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh"
else
    echo "Error: No se encontró common.sh en $SCRIPT_DIR"
    exit 1
fi

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🤖 Instalador de Configuración de IDEs de IA      ${NC}"
echo -e "${BLUE}            ai-agents OS v3.3.0                     ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Determinar rutas y directorios
PROJECT_ROOT="$(detect_project_root)"

# Determinar si está en modo submódulo
if [ -d "$PROJECT_ROOT/.ai/agents" ]; then
    IN_SUBMODULE=true
    echo -e "${GREEN}✓ Detectado proyecto raíz en: ${PROJECT_ROOT}${NC}"
    echo -e "${GREEN}✓ ai-agents está integrado como submódulo Git.${NC}"
elif [ "$PROJECT_ROOT" = "$AI_AGENTS_ROOT" ]; then
    IN_SUBMODULE=false
    echo -e "${YELLOW}! Ejecutando directamente en el repositorio ai-agents (modo desarrollo).${NC}"
else
    IN_SUBMODULE=false
    echo -e "${YELLOW}! No se detectó la carpeta .ai/agents/. Usando el directorio actual como raíz del proyecto.${NC}"
fi

# Ruta origen de las plantillas (dentro del repo de ai-agents)
TEMPLATES_DIR="$AI_AGENTS_ROOT/templates"
IDE_TEMPLATES_DIR="$TEMPLATES_DIR/ide-configs"

# Verificar que existen las plantillas
if [ ! -d "$IDE_TEMPLATES_DIR" ]; then
    echo -e "${RED}Error: No se encontró el directorio de plantillas en $IDE_TEMPLATES_DIR${NC}"
    exit 1
fi

echo -e "\n${BLUE}--- Paso 1: Verificación e Inicialización Documental ---${NC}"
if [ "$AUTO_MODE" = true ]; then
    init_ai="s"
    echo -e "${YELLOW}! Modo automático: inicializando estructura .ai/ si no existe.${NC}"
else
    read -p "¿Deseas inicializar la estructura documental (.ai/) con los archivos base si no existen? (s/n): " init_ai
fi

if [[ "$init_ai" =~ ^[sS]$ ]]; then
    echo -e "Creando estructura base en $PROJECT_ROOT/.ai/..."
    mkdir -p "$PROJECT_ROOT/.ai"
    mkdir -p "$PROJECT_ROOT/.ai/features"
    mkdir -p "$PROJECT_ROOT/.ai/archive"
    mkdir -p "$PROJECT_ROOT/.ai/sessions"

    # Crear context.md si no existe
    if [ ! -f "$PROJECT_ROOT/.ai/context.md" ]; then
        if [ -f "$TEMPLATES_DIR/project-context.md" ]; then
            cp "$TEMPLATES_DIR/project-context.md" "$PROJECT_ROOT/.ai/context.md"
            echo -e "${GREEN}✓ Creado .ai/context.md desde plantilla.${NC}"
        else
            cat << 'EOF' > "$PROJECT_ROOT/.ai/context.md"
# Contexto General del Proyecto

## 1. Visión General
[Descripción del producto y sus objetivos de negocio]

## 2. Stack Tecnológico
- **Frontend:** [ej. Next.js, React, TailwindCSS]
- **Backend:** [ej. Node.js, Express, Go]
- **Base de Datos:** [ej. PostgreSQL, Supabase]

## 3. Estado de Adopción
- Estado: EN_DESARROLLO

## 4. Registro de IDs
- **Última Feature:** FEAT-000
- **Último Bug:** BUG-000
- **Última Auditoría:** AUDIT-000
- **Último Refactor:** REF-000
- **Última Decisión Técnica:** DEC-000
- **Última Decisión de Arquitectura:** ARCH-000
- **Última Regla de Negocio:** RN-000
EOF
            echo -e "${GREEN}✓ Creado .ai/context.md inicial.${NC}"
        fi
    else
        echo -e "  - .ai/context.md ya existe. Omitido."
    fi

    # Crear business-rules.md si no existe
    if [ ! -f "$PROJECT_ROOT/.ai/business-rules.md" ]; then
        cat << 'EOF' > "$PROJECT_ROOT/.ai/business-rules.md"
# Reglas de Negocio del Sistema

Reglas inmutables y de dominio que todo agente y desarrollador debe respetar.

| ID | Regla | Descripción | Entidad Afectada | Estado |
| :--- | :--- | :--- | :--- | :--- |
| RN-001 | Regla de Ejemplo | Descripción detallada del comportamiento requerido | Dominio | ACTIVA |
EOF
        echo -e "${GREEN}✓ Creado .ai/business-rules.md inicial.${NC}"
    else
        echo -e "  - .ai/business-rules.md ya existe. Omitido."
    fi

    # Crear architecture.md si no existe
    if [ ! -f "$PROJECT_ROOT/.ai/architecture.md" ]; then
        cat << 'EOF' > "$PROJECT_ROOT/.ai/architecture.md"
# Arquitectura del Sistema

## 1. Diagrama de Alto Nivel
[Descripción o diagrama conceptual de componentes]

## 2. Patrones Arquitectónicos
- Patrón Principal: [ej. Clean Architecture, Modular Monolith]

## 3. Convenciones de Código
- Estilo: Standard
- Linting: Prettier / ESLint
EOF
        echo -e "${GREEN}✓ Creado .ai/architecture.md inicial.${NC}"
    else
        echo -e "  - .ai/architecture.md ya existe. Omitido."
    fi

    # Crear decisions.md si no existe
    if [ ! -f "$PROJECT_ROOT/.ai/decisions.md" ]; then
        cat << 'EOF' > "$PROJECT_ROOT/.ai/decisions.md"
# Registro de Decisiones de Arquitectura y Técnicas (ADR / DEC)

## [ARCH-001] Decisión de Arquitectura Inicial
*   **Fecha:** YYYY-MM-DD
*   **Estado:** APROBADO
*   **Contexto:** [Descripción del problema y por qué requiere una decisión técnica]
*   **Decisión:** [Detalle de la decisión adoptada]
*   **Consecuencias:** [Lo que ganamos y lo que perdemos con esta decisión]
EOF
        echo -e "${GREEN}✓ Creado .ai/decisions.md inicial.${NC}"
    else
        echo -e "  - .ai/decisions.md ya existe. Omitido."
    fi

    # Crear glossary.md si no existe
    if [ ! -f "$PROJECT_ROOT/.ai/glossary.md" ]; then
        cat << 'EOF' > "$PROJECT_ROOT/.ai/glossary.md"
# Glosario del Dominio

Definiciones claras de los conceptos clave utilizados en este proyecto.

| Término | Definición | Contexto / Notas |
| :--- | :--- | :--- |
| Ejemplo | Definición del término de ejemplo | Utilizado en todo el sistema |
EOF
        echo -e "${GREEN}✓ Creado .ai/glossary.md inicial.${NC}"
    else
        echo -e "  - .ai/glossary.md ya existe. Omitido."
    fi

    # Crear los sistemas de v3.2.0: memoria persistente, métricas y knowledge graph
    echo -e "\n${BLUE}  → Sistemas v3.2.0+: memoria persistente, métricas y knowledge graph${NC}"

    # Sistema de Memoria Persistente (.ai/memory/)
    mkdir -p "$PROJECT_ROOT/.ai/memory"
    echo -e "  - .ai/memory/ creada."

    # workflow-log.md — memoria episódica append-only
    if [ ! -f "$PROJECT_ROOT/.ai/memory/workflow-log.md" ]; then
        cat << 'EOF' > "$PROJECT_ROOT/.ai/memory/workflow-log.md"
# Memoria Episódica — Workflow Log (append-only)

Registro cronológico de las ejecuciones del pipeline. Cada agente, al terminar su
participación, agrega una entrada con fecha ISO-8601. **Nunca se reescribe una
entrada existente**; se agrega o se marca como `OBSOLETA`.

Formato por entrada:

## [FEAT-XXX] S# — Rol (YYYY-MM-DDTHH:MMZ)

- **Insumos consumidos:** [artefactos aprobados que se leyeron]
- **Decisión:** [qué se decidió, de forma precisa]
- **Razón:** [criterio detrás de la decisión]
- **Alternativas descartadas:** [opciones evaluadas y por qué se descartaron]
- **Riesgo detectado:** [RT-XX o ninguno]
- **Outputs producidos:** [vínculo al artefacto resultante]

Reglas:
1. Máximo ~6 bullets por entrada (~10 líneas).
2. Decisiones ≠ opiniones: registrar decisión, razón y alternativas.
3. `⚖️ OBSOLETA` para corregir, nunca borrar.

Referencia: docs/workflow-memory.md (framework ai-agents).
EOF
        echo -e "${GREEN}✓ Creado .ai/memory/workflow-log.md (memoria episódica).${NC}"
    else
        echo -e "  - .ai/memory/workflow-log.md ya existe. Omitido."
    fi

    # decisions-catalog.md — memoria semántica (índice de decisiones vigentes)
    if [ ! -f "$PROJECT_ROOT/.ai/memory/decisions-catalog.md" ]; then
        cat << 'EOF' > "$PROJECT_ROOT/.ai/memory/decisions-catalog.md"
# Catálogo de Decisiones — Memoria Semántica

Índice de decisiones **vigentes** con referencia al detalle en `decisions.md`
(que sigue siendo la fuente de verdad). El Architect mantiene este índice; el
Tech Lead o el Developer lo consultan antes de cada gate.

| ID | Decisión | Estado | Referencia | Última revisión |
|:---|:---|:---|:---|:---|
| DEC-001 | [Decisión] | ⚖️ Vigente / 🔄 En evaluación / ✖️ Descartada | [decisions.md](../../decisions.md#dec-001) | YYYY-MM-DD |

Reglas:
1. No duplica decisiones: cada fila referencia `decisions.md`.
2. Cambio de estado: `🔄 En evaluación` cuando hay propuesta, `⚖️ Vigente`/`✖️ Descartada` al resolver.

Referencia: docs/workflow-memory.md (framework ai-agents).
EOF
        echo -e "${GREEN}✓ Creado .ai/memory/decisions-catalog.md (memoria semántica).${NC}"
    else
        echo -e "  - .ai/memory/decisions-catalog.md ya existe. Omitido."
    fi

    # patterns-learned.md — memoria procedimental
    if [ ! -f "$PROJECT_ROOT/.ai/memory/patterns-learned.md" ]; then
        cat << 'EOF' > "$PROJECT_ROOT/.ai/memory/patterns-learned.md"
# Patrones Aprendidos — Memoria Procedimental

Lecciones y patrones reutilizables que aceleran el trabajo futuro. Solo patrones
que aplican a más de una ocasión; un one-off va al workflow-log.

Formato problema → causa → solución → aplica a:

## Problema: [Descripción breve]

- **Síntoma:** [comportamiento observado]
- **Causa raíz:** [por qué ocurría]
- **Solución aplicada:** [qué se hizo para resolverlo]
- **Aplica a:** [tipo de tarea futura donde aplica]

Referencia: docs/workflow-memory.md (framework ai-agents).
EOF
        echo -e "${GREEN}✓ Creado .ai/memory/patterns-learned.md (memoria procedimental).${NC}"
    else
        echo -e "  - .ai/memory/patterns-learned.md ya existe. Omitido."
    fi

    # context-snapshot.md — memoria compactada (generada por Skill Manager)
    if [ ! -f "$PROJECT_ROOT/.ai/memory/context-snapshot.md" ]; then
        cat << 'EOF' > "$PROJECT_ROOT/.ai/memory/context-snapshot.md"
# Context Snapshot — Memoria Compactada

> Generado por el **Skill Manager** al iniciar cada sesión.
> Este archivo se regenera (compacta `workflow-log.md` + `decisions-catalog.md` +
> `patterns-learned.md`) — **no se edita a mano**. Máximo ~30-50 líneas.

## Estado del proyecto

[Resumen ejecutivo de la sesión]

## Decisiones vigentes

[Índice rápido de decisiones ⚖️/🔄]

## Patrones relevantes

[Patrones aún aplicables]

Referencia: docs/workflow-memory.md (framework ai-agents).
EOF
        echo -e "${GREEN}✓ Creado .ai/memory/context-snapshot.md. Lo regenerará el Skill Manager.${NC}"
    else
        echo -e "  - .ai/memory/context-snapshot.md ya existe. Omitido."
    fi

    # Sistema de Métricas (.ai/metrics/executions.yaml)
    mkdir -p "$PROJECT_ROOT/.ai/metrics"
    if [ ! -f "$PROJECT_ROOT/.ai/metrics/executions.yaml" ]; then
        if [ -f "$TEMPLATES_DIR/metrics-executions.yaml" ]; then
            cp "$TEMPLATES_DIR/metrics-executions.yaml" "$PROJECT_ROOT/.ai/metrics/executions.yaml"
            echo -e "${GREEN}✓ Creado .ai/metrics/executions.yaml (registro de métricas por ejecución).${NC}"
        else
            echo -e "${YELLOW}! No se encontró templates/metrics-executions.yaml. Se omite el seed de métricas.${NC}"
        fi
    else
        echo -e "  - .ai/metrics/executions.yaml ya existe. Omitido."
    fi

    # Knowledge Graph (.ai/knowledge-graph.yaml)
    if [ ! -f "$PROJECT_ROOT/.ai/knowledge-graph.yaml" ]; then
        if [ -f "$TEMPLATES_DIR/knowledge-graph.yaml" ]; then
            cp "$TEMPLATES_DIR/knowledge-graph.yaml" "$PROJECT_ROOT/.ai/knowledge-graph.yaml"
            echo -e "${GREEN}✓ Creado .ai/knowledge-graph.yaml (grafo de decisiones arquitectónicas).${NC}"
        else
            echo -e "${YELLOW}! No se encontró templates/knowledge-graph.yaml. Se omite el seed del grafo.${NC}"
        fi
    else
        echo -e "  - .ai/knowledge-graph.yaml ya existe. Omitido."
    fi
else
    echo -e "Omitiendo inicialización de estructura documental .ai/"
fi

echo -e "\n${BLUE}--- Paso 2: Generación de Archivos de Reglas para IDEs ---${NC}"

ide_choice=10
if [ "$AUTO_MODE" = true ]; then
    echo -e "${YELLOW}! Modo automático: omitiendo generación de reglas de IDEs (ejecuta setup-ide.sh interactivo si lo necesitas).${NC}"
else
    echo "Selecciona qué archivos de reglas deseas generar en la raíz de tu proyecto:"
    echo "1) Cursor IDE (.cursorrules clásico)"
    echo "2) Cursor Modular Rules (.cursor/rules/*.mdc)"
    echo "3) Claude Code (CLAUDE.md)"
    echo "4) Windsurf IDE (.windsurfrules)"
    echo "5) Cline / Roo-Code (.clinerules)"
    echo "6) Roo-Code Custom Modes (.roomodes)"
    echo "7) GitHub Copilot (.github/copilot-instructions.md)"
    echo "8) Guía General de Agentes (AGENTS.md)"
    echo "9) Instalar TODOS los anteriores"
    echo "10) Ninguno"
    read -p "Ingresa tu opción (1-10): " ide_choice
fi

copy_rule_file() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [ -f "$src" ]; then
        # Crear directorio destino si no existe (ej. .github)
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        echo -e "${GREEN}✓ Creado $name en $dest${NC}"
    else
        echo -e "${RED}Error: No se encontró la plantilla para $name en $src${NC}"
    fi
}

copy_cursor_mdc_rules() {
    local src_dir="$IDE_TEMPLATES_DIR/cursor-rules"
    local dest_dir="$PROJECT_ROOT/.cursor/rules"
    if [ -d "$src_dir" ]; then
        mkdir -p "$dest_dir"
        cp -r "$src_dir/"* "$dest_dir/"
        echo -e "${GREEN}✓ Creadas reglas modulares de Cursor en $dest_dir (.mdc)${NC}"
    else
        echo -e "${RED}Error: No se encontró el directorio de reglas modulares en $src_dir${NC}"
    fi
}

case $ide_choice in
    1)
        copy_rule_file "$IDE_TEMPLATES_DIR/cursorrules" "$PROJECT_ROOT/.cursorrules" "Cursor (.cursorrules)"
        ;;
    2)
        copy_cursor_mdc_rules
        ;;
    3)
        copy_rule_file "$IDE_TEMPLATES_DIR/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md" "Claude Code (CLAUDE.md)"
        ;;
    4)
        copy_rule_file "$IDE_TEMPLATES_DIR/windsurfrules" "$PROJECT_ROOT/.windsurfrules" "Windsurf (.windsurfrules)"
        ;;
    5)
        copy_rule_file "$IDE_TEMPLATES_DIR/clinerules" "$PROJECT_ROOT/.clinerules" "Cline (.clinerules)"
        ;;
    6)
        copy_rule_file "$IDE_TEMPLATES_DIR/roomodes" "$PROJECT_ROOT/.roomodes" "Roo-Code (.roomodes)"
        ;;
    7)
        copy_rule_file "$IDE_TEMPLATES_DIR/copilot-instructions.md" "$PROJECT_ROOT/.github/copilot-instructions.md" "Copilot (.github/copilot-instructions.md)"
        ;;
    8)
        copy_rule_file "$IDE_TEMPLATES_DIR/AGENTS.md" "$PROJECT_ROOT/AGENTS.md" "Guía General (AGENTS.md)"
        ;;
    9)
        copy_rule_file "$IDE_TEMPLATES_DIR/cursorrules" "$PROJECT_ROOT/.cursorrules" "Cursor (.cursorrules)"
        copy_cursor_mdc_rules
        copy_rule_file "$IDE_TEMPLATES_DIR/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md" "Claude Code (CLAUDE.md)"
        copy_rule_file "$IDE_TEMPLATES_DIR/windsurfrules" "$PROJECT_ROOT/.windsurfrules" "Windsurf (.windsurfrules)"
        copy_rule_file "$IDE_TEMPLATES_DIR/clinerules" "$PROJECT_ROOT/.clinerules" "Cline (.clinerules)"
        copy_rule_file "$IDE_TEMPLATES_DIR/roomodes" "$PROJECT_ROOT/.roomodes" "Roo-Code (.roomodes)"
        copy_rule_file "$IDE_TEMPLATES_DIR/copilot-instructions.md" "$PROJECT_ROOT/.github/copilot-instructions.md" "Copilot (.github/copilot-instructions.md)"
        copy_rule_file "$IDE_TEMPLATES_DIR/AGENTS.md" "$PROJECT_ROOT/AGENTS.md" "Guía General (AGENTS.md)"
        ;;
    *)
        echo -e "Omitiendo generación de reglas de IDEs."
        ;;
esac

echo -e "\n${BLUE}--- Paso 3: Configuración de .gitignore ---${NC}"
# Preguntar si desea configurar el .gitignore
if [ "$AUTO_MODE" = true ]; then
    configure_git="s"
    echo -e "${YELLOW}! Modo automático: configurando .gitignore (.ai/sessions/).${NC}"
else
    read -p "¿Deseas agregar las carpetas de sesiones locales de IA y temporales al .gitignore del proyecto? (s/n): " configure_git
fi

if [[ "$configure_git" =~ ^[sS]$ ]]; then
    GITIGNORE_PATH="$PROJECT_ROOT/.gitignore"
    
    if [ ! -f "$GITIGNORE_PATH" ]; then
        touch "$GITIGNORE_PATH"
    fi

    # Verificar si ya está configurado
    if grep -q "\.ai/sessions/" "$GITIGNORE_PATH"; then
        echo -e "  - Las sesiones locales de IA ya están ignoradas en el .gitignore."
    else
        cat << 'EOF' >> "$GITIGNORE_PATH"

# ==============================================================================
# ai-agents OS — Ignorar carpetas temporales y de sesión local de IA
# ==============================================================================
.ai/sessions/
EOF
        echo -e "${GREEN}✓ Agregado .ai/sessions/ al .gitignore del proyecto.${NC}"
    fi
else
    echo -e "Omitiendo configuración de .gitignore."
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   🎉 ¡Configuración de ai-agents OS Completada!      ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Siguientes pasos recomendados:"
echo -e "1. Abre y edita ${YELLOW}.ai/context.md${NC} con la información técnica de tu proyecto."
echo -e "2. Completa los sistemas v3.2.0 recién creados:"
echo -e "   • ${YELLOW}.ai/knowledge-graph.yaml${NC} — indexa los ADRs ya vigentes en decisions.md"
echo -e "   • ${YELLOW}.ai/memory/workflow-log.md${NC} y ${YELLOW}.ai/memory/decisions-catalog.md${NC} — primer uso del pipeline"
echo -e "   • ${YELLOW}.ai/metrics/executions.yaml${NC} — se registra automáticamente en cada ejecución"
echo -e "3. Abre tu IDE de IA y comienza a trabajar siguiendo los agentes en ${YELLOW}AGENTS.md${NC}."
echo -e "4. Para proyectos que actualizan desde una versión previa: ver la guía de"
echo -e "   actualización en ${YELLOW}.ai/agents/docs/project-integration.md${NC} (§ Actualización)."
echo -e "===================================================="
