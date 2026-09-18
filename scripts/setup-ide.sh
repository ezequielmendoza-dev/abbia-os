#!/usr/bin/env bash

# ==============================================================================
# setup-ide.sh — Abbia OS Installer
# ==============================================================================
# Este script inicializa la estructura canónica .abbia/ (memoria 3-tier,
# métricas de telemetría y Knowledge Graph de decisiones) y genera los archivos
# de reglas para diferentes IDEs de IA en el proyecto donde se ejecuta.
#
# Uso:
#   bash setup-ide.sh             # interactivo
#   bash setup-ide.sh --auto      # no-interactivo
#   ./abbia setup
# ==============================================================================

set -euo pipefail

AUTO_MODE=false
if [ "${1:-}" = "--auto" ]; then
    AUTO_MODE=true
fi

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
echo -e "${CYAN}   🏗️   Instalador de Configuración de IDEs de IA     ${NC}"
echo -e "${CYAN}              Abbia OS v4.0.0                       ${NC}"
echo -e "${CYAN}====================================================${NC}"

# Determinar si está en modo submódulo
if [ -d "$ABBIA_CORE" ]; then
    IN_SUBMODULE=true
    echo -e "${GREEN}✓ Detectado proyecto raíz en: ${PROJECT_ROOT}${NC}"
    echo -e "${GREEN}✓ Abbia OS está integrado como submódulo en ${ABBIA_CORE#$PROJECT_ROOT/}.${NC}"
elif [ "$PROJECT_ROOT" = "$ABBIA_CORE_ROOT" ]; then
    IN_SUBMODULE=false
    echo -e "${YELLOW}! Ejecutando directamente en el repositorio core de Abbia (modo desarrollo).${NC}"
else
    IN_SUBMODULE=false
    echo -e "${YELLOW}! No se detectó submódulo. Usando el directorio actual como raíz del proyecto.${NC}"
fi

TEMPLATES_DIR="$ABBIA_CORE_ROOT/templates"
IDE_TEMPLATES_DIR="$TEMPLATES_DIR/ide-configs"

if [ ! -d "$IDE_TEMPLATES_DIR" ]; then
    echo -e "${RED}Error: No se encontró el directorio de plantillas en $IDE_TEMPLATES_DIR${NC}"
    exit 1
fi

echo -e "\n${BLUE}--- Paso 1: Verificación e Inicialización Documental ---${NC}"
if [ "$AUTO_MODE" = true ]; then
    init_abbia="s"
    echo -e "${YELLOW}! Modo automático: inicializando estructura ${ABBIA_DIR#$PROJECT_ROOT/}/ si no existe.${NC}"
else
    read -p "¿Deseas inicializar la estructura documental (${ABBIA_DIR#$PROJECT_ROOT/}/) con los archivos base si no existen? (s/n): " init_abbia
fi

if [[ "$init_abbia" =~ ^[sS]$ ]]; then
    echo -e "Creando estructura base en $ABBIA_DIR..."
    mkdir -p "$ABBIA_DIR"
    mkdir -p "$ABBIA_INITIATIVES_DIR"
    mkdir -p "$ABBIA_ARCHIVE_DIR"
    mkdir -p "$ABBIA_SESSIONS_DIR"

    # context.md
    if [ ! -f "$ABBIA_DIR/context.md" ]; then
        if [ -f "$TEMPLATES_DIR/project-context.md" ]; then
            cp "$TEMPLATES_DIR/project-context.md" "$ABBIA_DIR/context.md"
            echo -e "${GREEN}✓ Creado ${ABBIA_DIR#$PROJECT_ROOT/}/context.md desde plantilla.${NC}"
        else
            cat << 'EOF' > "$ABBIA_DIR/context.md"
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
            echo -e "${GREEN}✓ Creado ${ABBIA_DIR#$PROJECT_ROOT/}/context.md inicial.${NC}"
        fi
    else
        echo -e "  - ${ABBIA_DIR#$PROJECT_ROOT/}/context.md ya existe. Omitido."
    fi

    # business-rules.md
    if [ ! -f "$ABBIA_DIR/business-rules.md" ]; then
        cat << 'EOF' > "$ABBIA_DIR/business-rules.md"
# Reglas de Negocio del Sistema

Reglas inmutables y de dominio que todo agente y desarrollador debe respetar en Abbia OS.

| ID | Regla | Descripción | Entidad Afectada | Estado |
| :--- | :--- | :--- | :--- | :--- |
| RN-001 | Regla de Ejemplo | Descripción detallada del comportamiento requerido | Dominio | ACTIVA |
EOF
        echo -e "${GREEN}✓ Creado ${ABBIA_DIR#$PROJECT_ROOT/}/business-rules.md inicial.${NC}"
    else
        echo -e "  - ${ABBIA_DIR#$PROJECT_ROOT/}/business-rules.md ya existe. Omitido."
    fi

    # architecture.md
    if [ ! -f "$ABBIA_DIR/architecture.md" ]; then
        cat << 'EOF' > "$ABBIA_DIR/architecture.md"
# Arquitectura del Sistema

## 1. Diagrama de Alto Nivel
[Descripción o diagrama conceptual de componentes]

## 2. Patrones Arquitectónicos
- Patrón Principal: [ej. Clean Architecture, Modular Monolith]

## 3. Convenciones de Código
- Estilo: Standard
- Linting: Prettier / ESLint
EOF
        echo -e "${GREEN}✓ Creado ${ABBIA_DIR#$PROJECT_ROOT/}/architecture.md inicial.${NC}"
    else
        echo -e "  - ${ABBIA_DIR#$PROJECT_ROOT/}/architecture.md ya existe. Omitido."
    fi

    # decisions.md
    if [ ! -f "$ABBIA_DIR/decisions.md" ]; then
        cat << 'EOF' > "$ABBIA_DIR/decisions.md"
# Registro de Decisiones de Arquitectura y Técnicas (ADR / DEC)

## [ARCH-001] Decisión de Arquitectura Inicial
*   **Fecha:** YYYY-MM-DD
*   **Estado:** APROBADO
*   **Contexto:** [Descripción del problema y por qué requiere una decisión técnica]
*   **Decisión:** [Detalle de la decisión adoptada]
*   **Consecuencias:** [Lo que ganamos y lo que perdemos con esta decisión]
EOF
        echo -e "${GREEN}✓ Creado ${ABBIA_DIR#$PROJECT_ROOT/}/decisions.md inicial.${NC}"
    else
        echo -e "  - ${ABBIA_DIR#$PROJECT_ROOT/}/decisions.md ya existe. Omitido."
    fi

    # glossary.md
    if [ ! -f "$ABBIA_DIR/glossary.md" ]; then
        cat << 'EOF' > "$ABBIA_DIR/glossary.md"
# Glosario del Dominio

Definiciones claras de los conceptos clave utilizados en este proyecto.

| Término | Definición | Contexto / Notas |
| :--- | :--- | :--- |
| Ejemplo | Definición del término de ejemplo | Utilizado en todo el sistema |
EOF
        echo -e "${GREEN}✓ Creado ${ABBIA_DIR#$PROJECT_ROOT/}/glossary.md inicial.${NC}"
    else
        echo -e "  - ${ABBIA_DIR#$PROJECT_ROOT/}/glossary.md ya existe. Omitido."
    fi

    # Abbia 3-Tier Memory (.abbia/memory/)
    echo -e "\n${BLUE}  → Sistemas Abbia OS: 3-Tier Memory, Telemetría y Knowledge Graph${NC}"
    mkdir -p "$ABBIA_MEMORY_DIR"

    # workflow-log.md
    if [ ! -f "$ABBIA_MEMORY_DIR/workflow-log.md" ]; then
        cat << 'EOF' > "$ABBIA_MEMORY_DIR/workflow-log.md"
# Memoria Episódica — Workflow Log (append-only)

Registro cronológico de las ejecuciones del pipeline en Abbia OS. Cada agente, al terminar su
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

Referencia: docs/workflow-memory.md (Abbia OS).
EOF
        echo -e "${GREEN}✓ Creado ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/workflow-log.md (Tier 1: Memoria Episódica).${NC}"
    else
        echo -e "  - ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/workflow-log.md ya existe. Omitido."
    fi

    # patterns-learned.md
    if [ ! -f "$ABBIA_MEMORY_DIR/patterns-learned.md" ]; then
        cat << 'EOF' > "$ABBIA_MEMORY_DIR/patterns-learned.md"
# Patrones Aprendidos — Memoria Procedimental

Lecciones y patrones reutilizables que aceleran el trabajo futuro. Solo patrones
que aplican a más de una ocasión; un one-off va al workflow-log.

Formato problema → causa → solución → aplica a:

## Problema: [Descripción breve]

- **Síntoma:** [comportamiento observado]
- **Causa raíz:** [por qué ocurría]
- **Solución aplicada:** [qué se hizo para resolverlo]
- **Aplica a:** [tipo de tarea futura donde aplica]

Referencia: docs/workflow-memory.md (Abbia OS).
EOF
        echo -e "${GREEN}✓ Creado ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/patterns-learned.md (Tier 2: Memoria Procedimental).${NC}"
    else
        echo -e "  - ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/patterns-learned.md ya existe. Omitido."
    fi

    # context-snapshot.md
    if [ ! -f "$ABBIA_MEMORY_DIR/context-snapshot.md" ]; then
        cat << 'EOF' > "$ABBIA_MEMORY_DIR/context-snapshot.md"
# Context Snapshot — Memoria Compactada (Abbia 3-Tier Memory)

> Generado por finish-phase.sh / Skill Manager al culminar cada fase.
> Este archivo compacta `workflow-log.md` + `knowledge-graph.yaml` + `patterns-learned.md`.
> **No se edita a mano**. Máximo ~30-50 líneas.

## Estado del proyecto

(inicializado por Abbia OS setup)

## Decisiones vigentes

(sin decisiones vigentes)

## Patrones relevantes

(sin patrones registrados)

Referencia: docs/workflow-memory.md (Abbia OS).
EOF
        echo -e "${GREEN}✓ Creado ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/context-snapshot.md.${NC}"
    else
        echo -e "  - ${ABBIA_MEMORY_DIR#$PROJECT_ROOT/}/context-snapshot.md ya existe. Omitido."
    fi

    # Métricas (.abbia/metrics/executions.yaml)
    mkdir -p "$ABBIA_METRICS_DIR"
    if [ ! -f "$ABBIA_METRICS_DIR/executions.yaml" ]; then
        if [ -f "$TEMPLATES_DIR/metrics-executions.yaml" ]; then
            cp "$TEMPLATES_DIR/metrics-executions.yaml" "$ABBIA_METRICS_DIR/executions.yaml"
            echo -e "${GREEN}✓ Creado ${ABBIA_METRICS_DIR#$PROJECT_ROOT/}/executions.yaml (telemetría de ejecuciones).${NC}"
        fi
    else
        echo -e "  - ${ABBIA_METRICS_DIR#$PROJECT_ROOT/}/executions.yaml ya existe. Omitido."
    fi

    # Knowledge Graph (.abbia/knowledge-graph.yaml)
    if [ ! -f "$ABBIA_DIR/knowledge-graph.yaml" ]; then
        if [ -f "$TEMPLATES_DIR/knowledge-graph.yaml" ]; then
            cp "$TEMPLATES_DIR/knowledge-graph.yaml" "$ABBIA_DIR/knowledge-graph.yaml"
            echo -e "${GREEN}✓ Creado ${ABBIA_DIR#$PROJECT_ROOT/}/knowledge-graph.yaml (Tier 3: Grafo de Decisiones).${NC}"
        fi
    else
        echo -e "  - ${ABBIA_DIR#$PROJECT_ROOT/}/knowledge-graph.yaml ya existe. Omitido."
    fi

    # Copiar CLI wrapper ./abbia si no existe
    if [ ! -f "$PROJECT_ROOT/abbia" ] && [ -f "$TEMPLATES_DIR/abbia" ]; then
        cp "$TEMPLATES_DIR/abbia" "$PROJECT_ROOT/abbia"
        chmod +x "$PROJECT_ROOT/abbia"
        echo -e "${GREEN}✓ Instalado CLI wrapper ejecutable en ./abbia${NC}"
    fi
else
    echo -e "Omitiendo inicialización de estructura documental ${ABBIA_DIR#$PROJECT_ROOT/}."
fi

echo -e "\n${BLUE}--- Paso 2: Generación de Archivos de Reglas para IDEs ---${NC}"

ide_choice=10
if [ "$AUTO_MODE" = true ]; then
    echo -e "${YELLOW}! Modo automático: omitiendo generación interactiva de reglas de IDEs.${NC}"
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
    fi
}

case $ide_choice in
    1) copy_rule_file "$IDE_TEMPLATES_DIR/cursorrules" "$PROJECT_ROOT/.cursorrules" "Cursor (.cursorrules)" ;;
    2) copy_cursor_mdc_rules ;;
    3) copy_rule_file "$IDE_TEMPLATES_DIR/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md" "Claude Code (CLAUDE.md)" ;;
    4) copy_rule_file "$IDE_TEMPLATES_DIR/windsurfrules" "$PROJECT_ROOT/.windsurfrules" "Windsurf (.windsurfrules)" ;;
    5) copy_rule_file "$IDE_TEMPLATES_DIR/clinerules" "$PROJECT_ROOT/.clinerules" "Cline (.clinerules)" ;;
    6) copy_rule_file "$IDE_TEMPLATES_DIR/roomodes" "$PROJECT_ROOT/.roomodes" "Roo-Code (.roomodes)" ;;
    7) copy_rule_file "$IDE_TEMPLATES_DIR/copilot-instructions.md" "$PROJECT_ROOT/.github/copilot-instructions.md" "Copilot (.github/copilot-instructions.md)" ;;
    8) copy_rule_file "$IDE_TEMPLATES_DIR/AGENTS.md" "$PROJECT_ROOT/AGENTS.md" "Guía General Abbia (AGENTS.md)" ;;
    9)
        copy_rule_file "$IDE_TEMPLATES_DIR/cursorrules" "$PROJECT_ROOT/.cursorrules" "Cursor (.cursorrules)"
        copy_cursor_mdc_rules
        copy_rule_file "$IDE_TEMPLATES_DIR/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md" "Claude Code (CLAUDE.md)"
        copy_rule_file "$IDE_TEMPLATES_DIR/windsurfrules" "$PROJECT_ROOT/.windsurfrules" "Windsurf (.windsurfrules)"
        copy_rule_file "$IDE_TEMPLATES_DIR/clinerules" "$PROJECT_ROOT/.clinerules" "Cline (.clinerules)"
        copy_rule_file "$IDE_TEMPLATES_DIR/roomodes" "$PROJECT_ROOT/.roomodes" "Roo-Code (.roomodes)"
        copy_rule_file "$IDE_TEMPLATES_DIR/copilot-instructions.md" "$PROJECT_ROOT/.github/copilot-instructions.md" "Copilot (.github/copilot-instructions.md)"
        copy_rule_file "$IDE_TEMPLATES_DIR/AGENTS.md" "$PROJECT_ROOT/AGENTS.md" "Guía General Abbia (AGENTS.md)"
        ;;
    *)
        echo -e "Omitiendo generación de reglas de IDEs."
        ;;
esac

echo -e "\n${BLUE}--- Paso 3: Configuración de .gitignore y .gitattributes ---${NC}"
if [ "$AUTO_MODE" = true ]; then
    configure_git="s"
    echo -e "${YELLOW}! Modo automático: configurando .gitignore y .gitattributes para Abbia OS.${NC}"
else
    read -p "¿Deseas configurar .gitignore y .gitattributes para evitar conflictos en Git? (s/n): " configure_git
fi

if [[ "$configure_git" =~ ^[sS]$ ]]; then
    GITIGNORE_PATH="$PROJECT_ROOT/.gitignore"
    [ ! -f "$GITIGNORE_PATH" ] && touch "$GITIGNORE_PATH"

    ENTRIES_ADDED=0
    target_prefix="${ABBIA_DIR#$PROJECT_ROOT/}"
    for entry in "$target_prefix/sessions/" "$target_prefix/dashboard.html" "$target_prefix/memory/context-snapshot.md" "$target_prefix/metrics/aggregates.yaml"; do
        if ! grep -qF "$entry" "$GITIGNORE_PATH"; then
            if [ $ENTRIES_ADDED -eq 0 ] && ! grep -q "Abbia OS" "$GITIGNORE_PATH"; then
                echo -e "\n# ==============================================================================\n# Abbia OS — Archivos temporales, sesiones y cachés generados\n# ==============================================================================" >> "$GITIGNORE_PATH"
            fi
            echo "$entry" >> "$GITIGNORE_PATH"
            ENTRIES_ADDED=$((ENTRIES_ADDED + 1))
        fi
    done

    if [ $ENTRIES_ADDED -gt 0 ]; then
        echo -e "${GREEN}✓ Agregadas reglas de Abbia OS a .gitignore ($ENTRIES_ADDED nuevas entradas).${NC}"
    else
        echo -e "  - Reglas de .gitignore ya configuradas."
    fi

    GITATTRIBUTES_PATH="$PROJECT_ROOT/.gitattributes"
    [ ! -f "$GITATTRIBUTES_PATH" ] && touch "$GITATTRIBUTES_PATH"

    ATTR_ADDED=0
    for attr in "$target_prefix/memory/workflow-log.md merge=union" "$target_prefix/metrics/executions.yaml merge=union"; do
        if ! grep -qF "$attr" "$GITATTRIBUTES_PATH"; then
            if [ $ATTR_ADDED -eq 0 ] && ! grep -q "Abbia OS" "$GITATTRIBUTES_PATH"; then
                echo -e "\n# ==============================================================================\n# Abbia OS — Reglas de Merge para Git (.gitattributes)\n# ==============================================================================" >> "$GITATTRIBUTES_PATH"
            fi
            echo "$attr" >> "$GITATTRIBUTES_PATH"
            ATTR_ADDED=$((ATTR_ADDED + 1))
        fi
    done

    if [ $ATTR_ADDED -gt 0 ]; then
        echo -e "${GREEN}✓ Agregadas reglas de merge=union a .gitattributes para logs append-only.${NC}"
    else
        echo -e "  - Reglas de .gitattributes ya configuradas."
    fi
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}     🎉 ¡Configuración de Abbia OS Completada!      ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Siguientes pasos recomendados:"
echo -e "1. Abre y edita ${YELLOW}${ABBIA_DIR#$PROJECT_ROOT/}/context.md${NC} con la información de tu proyecto."
echo -e "2. Ejecuta ${GREEN}./abbia new FEAT 001 mi-feature${NC} para crear tu primera iniciativa."
echo -e "3. Abre el visualizador con: ${GREEN}./abbia dashboard${NC}"
echo -e "===================================================="
