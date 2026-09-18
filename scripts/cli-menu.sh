#!/usr/bin/env bash

# ==============================================================================
# cli-menu.sh — Abbia OS Interactive Console Dashboard & CLI Center
# ==============================================================================
# Panel interactivo en terminal para descubrir, consultar y ejecutar cualquier
# script de Abbia OS sin necesidad de recordar rutas ni parámetros complejos.
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

# Estilos y colores
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # Sin color

# Helper para imprimir separador
print_line() {
    echo -e "${DIM}────────────────────────────────────────────────────────────────────────${NC}"
}

# Obtener estadísticas rápidas del proyecto
get_project_summary() {
    ACTIVE_COUNT=0
    ARCHIVED_COUNT=0
    ADR_COUNT=0
    LOG_ENTRIES=0
    
    if [ -d "$ABBIA_INITIATIVES_DIR" ]; then
        shopt -s nullglob
        local inits=("$ABBIA_INITIATIVES_DIR"/*/)
        shopt -u nullglob
        ACTIVE_COUNT=${#inits[@]}
    fi

    if [ -d "$ABBIA_ARCHIVE_DIR" ]; then
        shopt -s nullglob
        local archs=("$ABBIA_ARCHIVE_DIR"/*/)
        shopt -u nullglob
        ARCHIVED_COUNT=${#archs[@]}
    fi

    if [ -f "$ABBIA_DIR/knowledge-graph.yaml" ]; then
        ADR_COUNT=$( (grep -cE '^[[:space:]]*- id: ARCH-[0-9]{3}' "$ABBIA_DIR/knowledge-graph.yaml" 2>/dev/null || true) | tr -cd '0-9' )
        ADR_COUNT=${ADR_COUNT:-0}
        local placeholders=$( (grep -cE '^[[:space:]]*title: "Nombre corto de la decisión"' "$ABBIA_DIR/knowledge-graph.yaml" 2>/dev/null || true) | tr -cd '0-9' )
        placeholders=${placeholders:-0}
        ADR_COUNT=$(( ADR_COUNT - placeholders ))
        [ "$ADR_COUNT" -lt 0 ] && ADR_COUNT=0
    fi

    if [ -f "$ABBIA_MEMORY_DIR/workflow-log.md" ]; then
        LOG_ENTRIES=$( (grep -cE '^## \[(FEAT|BUG|AUDIT|REF)-[0-9]{3}\]' "$ABBIA_MEMORY_DIR/workflow-log.md" 2>/dev/null || true) | tr -cd '0-9' )
        LOG_ENTRIES=${LOG_ENTRIES:-0}
    fi
}

# Mostrar encabezado y estado del proyecto
show_header() {
    clear 2>/dev/null || echo ""
    get_project_summary
    
    echo -e "${CYAN}${BOLD}           ▲${NC}"
    echo -e "${CYAN}${BOLD}          ╱ ╲       ${BOLD}ABBIA OS${NC} ${CYAN}${BOLD}│ v4.0.0${NC}"
    echo -e "${CYAN}${BOLD}         ╱╱ ╲╲      ${DIM}AI Software Engineering Operating System${NC}"
    echo -e "${CYAN}${BOLD}        ╱╱   ╲╲     ${DIM}\"Layered Context · Structured Memory · Autonomous Delivery\"${NC}"
    echo -e "${GREEN}${BOLD}       ●═══${MAGENTA}◆${GREEN}═══●${NC}"
    echo -e "${CYAN}${BOLD}      ╱╱       ╲╲${NC}"
    echo -e "${GREEN}${BOLD}     ●═══════════●${NC}"
    echo ""
    echo -e "${BOLD}📁 Proyecto:${NC} ${YELLOW}$PROJECT_ROOT${NC}"
    echo -e "${BOLD}📊 Estado:${NC}   ${GREEN}$ACTIVE_COUNT Activas${NC} │ ${BLUE}$ARCHIVED_COUNT Archivadas${NC} │ ${MAGENTA}$ADR_COUNT ADRs${NC} │ ${CYAN}$LOG_ENTRIES Logs de Sesión${NC}"
    print_line
}

# Listar iniciativas activas de forma visual
show_active_initiatives_list() {
    if [ ! -d "$ABBIA_INITIATIVES_DIR" ]; then
        echo -e "${DIM}  (No hay directorio de iniciativas)${NC}"
        return
    fi
    
    shopt -s nullglob
    local dirs=("$ABBIA_INITIATIVES_DIR"/*/)
    shopt -u nullglob
    
    if [ ${#dirs[@]} -eq 0 ]; then
        echo -e "${GREEN}  ✓ No hay iniciativas activas pendientes de cierre.${NC}"
    else
        echo -e "${BOLD}Iniciativas en Desarrollo:${NC}"
        for d in "${dirs[@]}"; do
            local bname=$(basename "$d")
            local spec_badge="${DIM}[spec: -]${NC}"
            local arch_badge="${DIM}[arch: -]${NC}"
            local qa_badge="${DIM}[qa: -]${NC}"
            
            [ -f "$d/spec.md" ] && spec_badge="${GREEN}[spec: ✓]${NC}"
            [ -f "$d/architecture.md" ] && arch_badge="${BLUE}[arch: ✓]${NC}"
            if [ -f "$d/qa.md" ]; then
                if grep -iqE '(veredicto|estado|resultado)\*{0,2}[[:space:]]*[:—–-][^A-Za-z0-9]*(APROBADO|PASS)' "$d/qa.md" || grep -iqE '###[[:space:]]*Veredicto.*(APROBADO|PASS)' "$d/qa.md"; then
                    qa_badge="${GREEN}[qa: APROBADO]${NC}"
                elif grep -iqE '(veredicto|estado|resultado)\*{0,2}[[:space:]]*[:—–-][^A-Za-z0-9]*(RECHAZADO|FAIL)' "$d/qa.md" || grep -iqE '###[[:space:]]*Veredicto.*(RECHAZADO|FAIL)' "$d/qa.md"; then
                    qa_badge="${RED}[qa: RECHAZADO]${NC}"
                else
                    qa_badge="${YELLOW}[qa: PENDIENTE]${NC}"
                fi
            fi
            echo -e "  • ${YELLOW}$bname${NC} $spec_badge $arch_badge $qa_badge"
        done
    fi
    print_line
}

# Menú principal interactivo
main_menu() {
    while true; do
        show_header
        show_active_initiatives_list

        echo -e "${BOLD}Selecciona una acción:${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}1)${NC} 🚀 ${BOLD}Crear Nueva Iniciativa${NC} ${DIM}(./abbia new <TIPO> <ID> <slug>)${NC}"
        echo -e "     ${DIM}Genera una nueva feature, bug, auditoría o refactor con sus artefactos.${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}2)${NC} 🏁 ${BOLD}Cerrar Fase & Telemetría${NC} ${DIM}(./abbia finish <INIT> <FASE> [ROL])${NC}"
        echo -e "     ${DIM}Registra la fase completada, guarda tokens, duración y snapshot.${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}3)${NC} 📦 ${BOLD}Archivar Iniciativa${NC} ${DIM}(./abbia archive <INIT>)${NC}"
        echo -e "     ${DIM}Mueve iniciativa con QA Aprobado a .abbia/archive/ y actualiza el grafo.${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}4)${NC} 🔄 ${BOLD}Sincronizar & Auto-Reparar${NC} ${DIM}(./abbia sync --fix)${NC}"
        echo -e "     ${DIM}Reconcilia iniciativas con el Knowledge Graph y telemetría.${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}5)${NC} 🔍 ${BOLD}Validar Conformidad del Proyecto${NC} ${DIM}(./abbia validate)${NC}"
        echo -e "     ${DIM}Audita estructura, invariantes, QA gates e higiene de Git.${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}6)${NC} 📊 ${BOLD}Abrir Dashboard Visual Web${NC} ${DIM}(./abbia dashboard)${NC}"
        echo -e "     ${DIM}Genera y abre la interfaz gráfica con telemetría FinOps y grafo 2D.${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}7)${NC} 🧠 ${BOLD}Ver Context Snapshot en Consola${NC} ${DIM}(.abbia/memory/context-snapshot.md)${NC}"
        echo -e "     ${DIM}Muestra el resumen ejecutivo actual de memoria persistente.${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}8)${NC} 🛠️ ${BOLD}Instalar / Regenerar Reglas de IDE${NC} ${DIM}(./abbia setup)${NC}"
        echo -e "     ${DIM}Genera o actualiza Cursor, Claude Code, Windsurf, Cline, Copilot.${NC}"
        echo ""
        echo -e "  ${GREEN}${BOLD}9)${NC} 🔄 ${BOLD}Actualizar Framework Abbia OS${NC} ${DIM}(./abbia update)${NC}"
        echo -e "     ${DIM}Actualiza el submódulo core a la última versión disponible.${NC}"
        echo ""
        echo -e "  ${RED}${BOLD}0)${NC} 🚪 ${BOLD}Salir${NC}"
        print_line

        read -p "Ingresa tu opción (0-9): " choice

        case "$choice" in
            1)
                echo -e "\n${BLUE}=== Crear Nueva Iniciativa ===${NC}"
                bash "$SCRIPT_DIR/new-initiative.sh"
                read -p "Presiona Enter para continuar..." dummy
                ;;
            2)
                echo -e "\n${BLUE}=== Cerrar Fase de Iniciativa ===${NC}"
                shopt -s nullglob
                local inits=("$ABBIA_INITIATIVES_DIR"/*/)
                shopt -u nullglob
                
                if [ ${#inits[@]} -eq 0 ]; then
                    echo -e "${YELLOW}No hay iniciativas activas para cerrar fases.${NC}"
                else
                    echo "Iniciativas activas disponibles:"
                    local idx=1
                    local init_keys=()
                    for d in "${inits[@]}"; do
                        local bname=$(basename "$d")
                        echo "  $idx) $bname"
                        init_keys+=("$bname")
                        idx=$((idx + 1))
                    done
                    read -p "Selecciona la iniciativa (1-${#init_keys[@]}): " sel_idx
                    if [ "$sel_idx" -ge 1 ] 2>/dev/null && [ "$sel_idx" -le "${#init_keys[@]}" ] 2>/dev/null; then
                        selected_init="${init_keys[$((sel_idx - 1))]}"
                        echo -e "\nFases canónicas del DAG: ${CYAN}spec discovery ui-design architecture implement tasks qa approval deploy${NC}"
                        read -p "Ingresa la fase completada (ej: spec, implement, qa): " sel_phase
                        read -p "Ingresa el rol ejecutante [opcional, Enter para auto]: " sel_role
                        read -p "Modelo utilizado [ej: claude-3-7-sonnet / Enter para omitir]: " sel_model
                        read -p "Tokens de entrada consumidos [ej: 3500 / Enter para null]: " sel_tok_in
                        read -p "Tokens de salida generados [ej: 1200 / Enter para null]: " sel_tok_out
                        read -p "Duración en segundos [ej: 45 / Enter para null]: " sel_dur
                        read -p "Nota o decisión clave [opcional]: " sel_note

                        cmd_args=("$selected_init" "$sel_phase")
                        [ -n "$sel_role" ] && cmd_args+=("$sel_role")
                        [ -n "$sel_model" ] && cmd_args+=(--model "$sel_model")
                        [ -n "$sel_tok_in" ] && cmd_args+=(--tokens-in "$sel_tok_in")
                        [ -n "$sel_tok_out" ] && cmd_args+=(--tokens-out "$sel_tok_out")
                        [ -n "$sel_dur" ] && cmd_args+=(--duration "$sel_dur")
                        [ -n "$sel_note" ] && cmd_args+=(--note "$sel_note")
                        [ -n "$sel_tok_in" ] && cmd_args+=(--source measured)

                        bash "$SCRIPT_DIR/finish-phase.sh" "${cmd_args[@]}"
                    else
                        echo -e "${RED}Opción inválida.${NC}"
                    fi
                fi
                read -p "Presiona Enter para continuar..." dummy
                ;;
            3)
                echo -e "\n${BLUE}=== Archivar Iniciativa Completada ===${NC}"
                shopt -s nullglob
                local inits=("$ABBIA_INITIATIVES_DIR"/*/)
                shopt -u nullglob
                
                if [ ${#inits[@]} -eq 0 ]; then
                    echo -e "${YELLOW}No hay iniciativas activas para archivar.${NC}"
                else
                    echo "Selecciona la iniciativa a archivar:"
                    local idx=1
                    local init_keys=()
                    for d in "${inits[@]}"; do
                        local bname=$(basename "$d")
                        echo "  $idx) $bname"
                        init_keys+=("$bname")
                        idx=$((idx + 1))
                    done
                    read -p "Ingresa número (1-${#init_keys[@]}): " sel_idx
                    if [ "$sel_idx" -ge 1 ] 2>/dev/null && [ "$sel_idx" -le "${#init_keys[@]}" ] 2>/dev/null; then
                        selected_init="${init_keys[$((sel_idx - 1))]}"
                        bash "$SCRIPT_DIR/archive-initiative.sh" "$selected_init"
                    else
                        echo -e "${RED}Opción inválida.${NC}"
                    fi
                fi
                read -p "Presiona Enter para continuar..." dummy
                ;;
            4)
                echo -e "\n${BLUE}=== Sincronizar & Auto-Reparar ===${NC}"
                bash "$SCRIPT_DIR/sync-initiatives.sh" --fix
                read -p "Presiona Enter para continuar..." dummy
                ;;
            5)
                echo -e "\n${BLUE}=== Validar Conformidad del Proyecto ===${NC}"
                bash "$SCRIPT_DIR/validate-project.sh" || true
                read -p "Presiona Enter para continuar..." dummy
                ;;
            6)
                echo -e "\n${BLUE}=== Lanzar Dashboard Web Interactivo ===${NC}"
                bash "$SCRIPT_DIR/dashboard.sh"
                read -p "Presiona Enter para continuar..." dummy
                ;;
            7)
                echo -e "\n${BLUE}=== Context Snapshot (Memoria Compactada) ===${NC}"
                if [ -f "$ABBIA_MEMORY_DIR/context-snapshot.md" ]; then
                    cat "$ABBIA_MEMORY_DIR/context-snapshot.md"
                else
                    echo -e "${YELLOW}No se encontró .abbia/memory/context-snapshot.md. Ejecutando regeneración...${NC}"
                    regenerate_context_snapshot "$PROJECT_ROOT"
                    cat "$ABBIA_MEMORY_DIR/context-snapshot.md"
                fi
                read -p "Presiona Enter para continuar..." dummy
                ;;
            8)
                echo -e "\n${BLUE}=== Configuración de IDEs ===${NC}"
                bash "$SCRIPT_DIR/setup-ide.sh"
                read -p "Presiona Enter para continuar..." dummy
                ;;
            9)
                echo -e "\n${BLUE}=== Actualizar Framework Abbia OS ===${NC}"
                if [ -f "$SCRIPT_DIR/update-abbia.sh" ]; then
                    bash "$SCRIPT_DIR/update-abbia.sh"
                fi
                read -p "Presiona Enter para continuar..." dummy
                ;;
            0|q|Q|exit)
                echo -e "\n${GREEN}¡Hasta la próxima sesión de ingeniería con Abbia OS! 🎛️${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Opción no reconocida: '$choice'. Intenta nuevamente.${NC}"
                sleep 1
                ;;
        esac
    done
}

main_menu
