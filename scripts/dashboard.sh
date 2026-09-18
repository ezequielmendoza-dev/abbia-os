#!/usr/bin/env bash

# ==============================================================================
# dashboard.sh — Abbia OS Interactive Dashboard & Visualizer
# ==============================================================================
# Dashboard visual y autónomo para el equipo de desarrollo (Abbia OS).
# Proporciona visibilidad real y objetiva sobre:
#   1. Iniciativas & Pipeline SDD (Features, Bugs, Refactors, Documentación y QA)
#   2. Knowledge Graph (Grafo de Decisiones Arquitectónicas ADR y dependencias)
#   3. Reglas de Negocio & Glosario (Definiciones del dominio)
#   4. Memoria Técnica (Snapshot, lecciones aprendidas y bitácora de sesiones)
#   5. Telemetría de Agentes (Tokens reales in/out, fases y tiempos de ejecución)
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
resolve_abbia_paths "$PROJECT_ROOT"

NO_OPEN=0
WATCH_MODE=0
SERVE_MODE=0
PORT=4242

while [ $# -gt 0 ]; do
    case "$1" in
        --no-open)
            NO_OPEN=1
            shift
            ;;
        --watch|-w)
            WATCH_MODE=1
            shift
            ;;
        --serve|-s|--server)
            SERVE_MODE=1
            shift
            ;;
        --port|-p)
            PORT="${2:-4242}"
            shift 2
            ;;
        -h|--help)
            echo "Uso: bash dashboard.sh [OPCIONES] o ./abbia dashboard [OPCIONES]"
            echo ""
            echo "Opciones:"
            echo "  --no-open             Genera el dashboard sin abrir el navegador"
            echo "  --watch, -w           Vigila cambios en .abbia/ y regenera automáticamente"
            echo "  --serve, -s           Inicia un servidor local en http://localhost:PORT con Live Reload"
            echo "  --port, -p <PORT>     Puerto para el servidor local (default: 4242)"
            echo "  -h, --help            Muestra esta ayuda"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   📊 Visualizador Interactivo (Abbia OS v4.0.0)    ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Raíz del proyecto: ${YELLOW}$PROJECT_ROOT${NC}\n"

AI_DIR="$ABBIA_DIR"
if [ ! -d "$AI_DIR" ]; then
    echo -e "${RED}Error: No se encontró la carpeta ($AI_DIR) en $PROJECT_ROOT${NC}"
    exit 1
fi


KG_FILE="$ABBIA_DIR/knowledge-graph.yaml"
METRICS_FILE="$ABBIA_METRICS_DIR/executions.yaml"
MEM_DIR="$ABBIA_MEMORY_DIR"
LOG_FILE="$MEM_DIR/workflow-log.md"
CATALOG_FILE="$MEM_DIR/decisions-catalog.md"
PATTERNS_FILE="$MEM_DIR/patterns-learned.md"
SNAPSHOT_FILE="$MEM_DIR/context-snapshot.md"
CONTEXT_FILE="$ABBIA_DIR/context.md"
RULES_FILE="$ABBIA_DIR/business-rules.md"
GLOSSARY_FILE="$ABBIA_DIR/glossary.md"
FEATURES_DIR="$ABBIA_INITIATIVES_DIR"
ARCHIVE_DIR="$ABBIA_ARCHIVE_DIR"

# Leer y sanitizar contenidos para inyección JSON
read_file_or_default() {
    local filepath="$1"
    local default_val="$2"
    if [ -f "$filepath" ]; then
        cat "$filepath"
    else
        echo "$default_val"
    fi
}

# Escanear iniciativas reales en .ai/features/ y .ai/archive/
scan_initiatives_json() {
    local features_dir="$1"
    local archive_dir="$2"
    local first=1

    echo "["
    for base in "$features_dir" "$archive_dir"; do
        [ ! -d "$base" ] && continue
        local status="ACTIVE"
        if [ "$base" = "$archive_dir" ]; then
            status="ARCHIVED"
        fi

        for dir in "$base"/*; do
            [ ! -d "$dir" ] && continue
            local folder="$(basename "$dir")"
            [ "$folder" = "*" ] && continue
            [ "$folder" = ".gitkeep" ] && continue

            local itype="OTHER"
            if [[ "$folder" =~ ^FEAT- ]]; then itype="FEAT"; fi
            if [[ "$folder" =~ ^BUG- ]]; then itype="BUG"; fi
            if [[ "$folder" =~ ^AUDIT- ]]; then itype="AUDIT"; fi
            if [[ "$folder" =~ ^REF- ]]; then itype="REF"; fi

            local has_spec=false
            local has_ui=false
            local has_arch=false
            local has_qa=false
            local has_dec=false
            local has_bug=false
            local qa_verdict="PENDING"
            local title=""

            [ -f "$dir/spec.md" ] && has_spec=true
            [ -f "$dir/ui-design.md" ] && has_ui=true
            [ -f "$dir/architecture.md" ] && has_arch=true
            [ -f "$dir/decision.md" ] && has_dec=true
            [ -f "$dir/bug-report.md" ] && has_bug=true

            if [ -f "$dir/spec.md" ]; then
                title=$(grep -E '^# ' "$dir/spec.md" | head -1 | sed 's/^# //' | tr -d '"\r\n\\' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
            elif [ -f "$dir/bug-report.md" ]; then
                title=$(grep -E '^# ' "$dir/bug-report.md" | head -1 | sed 's/^# //' | tr -d '"\r\n\\' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
            elif [ -f "$dir/README.md" ]; then
                title=$(grep -E '^# ' "$dir/README.md" | head -1 | sed 's/^# //' | tr -d '"\r\n\\' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
            fi

            if [ -f "$dir/qa.md" ]; then
                has_qa=true
                if grep -qi "APROBADO" "$dir/qa.md" 2>/dev/null; then
                    qa_verdict="APROBADO"
                elif grep -qi "RECHAZADO" "$dir/qa.md" 2>/dev/null; then
                    qa_verdict="RECHAZADO"
                fi
            fi

            if [ -z "$title" ]; then
                title="$folder"
            fi

            # Clean json escape
            title=$(echo "$title" | sed 's/\\/\\\\/g; s/"/\\"/g')

            if [ "$first" -eq 0 ]; then
                echo ","
            fi
            first=0

            printf '  {"id":"%s","name":"%s","type":"%s","status":"%s","title":"%s","has_spec":%s,"has_ui":%s,"has_arch":%s,"has_qa":%s,"has_decision":%s,"has_bug":%s,"qa_verdict":"%s"}' \
                "$folder" "$folder" "$itype" "$status" "$title" "$has_spec" "$has_ui" "$has_arch" "$has_qa" "$has_dec" "$has_bug" "$qa_verdict"
        done
    done
    echo ""
    echo "]"
}

# Extraer datos reales del proyecto
KG_RAW=$(read_file_or_default "$KG_FILE" "version: 1\nnodes: []\nedges: []")
METRICS_RAW=$(read_file_or_default "$METRICS_FILE" "executions: []")
LOG_RAW=$(read_file_or_default "$LOG_FILE" "(sin entradas en workflow-log.md)")
CATALOG_RAW=$(read_file_or_default "$CATALOG_FILE" "(sin catálogo)")
PATTERNS_RAW=$(read_file_or_default "$PATTERNS_FILE" "(sin patrones aprendidos)")
SNAPSHOT_RAW=$(read_file_or_default "$SNAPSHOT_FILE" "(sin snapshot)")
CONTEXT_RAW=$(read_file_or_default "$CONTEXT_FILE" "(sin context.md)")
RULES_RAW=$(read_file_or_default "$RULES_FILE" "(sin business-rules.md)")
GLOSSARY_RAW=$(read_file_or_default "$GLOSSARY_FILE" "(sin glossary.md)")
INITIATIVES_RAW=$(scan_initiatives_json "$FEATURES_DIR" "$ARCHIVE_DIR")

# Extraer metadata de alto nivel del proyecto para el header y tab de proyecto
PROJECT_BASENAME="$(basename "$PROJECT_ROOT")"
PROJECT_TITLE=""
PROJECT_TYPE=""
PROJECT_STATUS=""
PROJECT_START=""
PROJECT_UPDATED=""
PROJECT_REPO=""

if [ -f "$CONTEXT_FILE" ]; then
    PROJECT_TITLE=$(grep -E '\|\s*\*\*Nombre del Proyecto\*\*\s*\|' "$CONTEXT_FILE" | head -1 | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
    if [ -z "$PROJECT_TITLE" ] || [[ "$PROJECT_TITLE" =~ ^\[.*\]$ ]]; then
        PROJECT_TITLE=$(grep -E '^# ' "$CONTEXT_FILE" | head -1 | sed 's/^# //' | sed 's/ — Contexto del Proyecto//' | sed 's/ - Contexto del Proyecto//' | sed 's/ — Project Context//' | sed 's/ - Project Context//' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
    fi
    PROJECT_TYPE=$(grep -E '\|\s*\*\*Tipo\*\*\s*\|' "$CONTEXT_FILE" | head -1 | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
    PROJECT_STATUS=$(grep -E '\|\s*\*\*Estado\*\*\s*\|' "$CONTEXT_FILE" | head -1 | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
    PROJECT_START=$(grep -E '\|\s*\*\*Fecha de inicio\*\*\s*\|' "$CONTEXT_FILE" | head -1 | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
    PROJECT_UPDATED=$(grep -E '\|\s*\*\*Última actualización\*\*\s*\|' "$CONTEXT_FILE" | head -1 | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
    PROJECT_REPO=$(grep -E '\|\s*\*\*Repositorio principal\*\*\s*\|' "$CONTEXT_FILE" | head -1 | awk -F'|' '{print $3}' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' || true)
fi

[ -z "$PROJECT_TITLE" ] && PROJECT_TITLE="$PROJECT_BASENAME"
[ -z "$PROJECT_TYPE" ] || [[ "$PROJECT_TYPE" =~ ^\[.*\]$ ]] && PROJECT_TYPE="Aplicación / Software"
[ -z "$PROJECT_STATUS" ] || [[ "$PROJECT_STATUS" =~ ^\[.*\]$ ]] && PROJECT_STATUS="Activo"
[ -z "$PROJECT_UPDATED" ] || [[ "$PROJECT_UPDATED" =~ ^\[.*\]$ ]] && PROJECT_UPDATED="$(date -u +"%Y-%m-%d")"

# Sanitizar comillas para JSON seguro
PROJECT_TITLE_ESC=$(echo "$PROJECT_TITLE" | sed 's/"/\\"/g')
PROJECT_TYPE_ESC=$(echo "$PROJECT_TYPE" | sed 's/"/\\"/g')
PROJECT_STATUS_ESC=$(echo "$PROJECT_STATUS" | sed 's/"/\\"/g')
PROJECT_REPO_ESC=$(echo "$PROJECT_REPO" | sed 's/"/\\"/g')
PROJECT_ROOT_ESC=$(echo "$PROJECT_ROOT" | sed 's/"/\\"/g')
PROJECT_START_ESC=$(echo "$PROJECT_START" | sed 's/"/\\"/g')
PROJECT_UPDATED_ESC=$(echo "$PROJECT_UPDATED" | sed 's/"/\\"/g')

PROJECT_META_JSON="{\"name\": \"$PROJECT_TITLE_ESC\", \"type\": \"$PROJECT_TYPE_ESC\", \"status\": \"$PROJECT_STATUS_ESC\", \"repo\": \"$PROJECT_REPO_ESC\", \"root\": \"$PROJECT_ROOT_ESC\", \"startDate\": \"$PROJECT_START_ESC\", \"updatedDate\": \"$PROJECT_UPDATED_ESC\", \"basename\": \"$PROJECT_BASENAME\"}"

OUTPUT_HTML="$AI_DIR/dashboard.html"

# Generar archivo HTML interactivo autónomo
cat << 'HTML_HEADER' > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="es" class="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Abbia OS — Interactive Visualizer</title>
  <script src="https://cdn.tailwindcss.com?plugins=typography"></script>
  <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/js-yaml/dist/js-yaml.min.js"></script>
  <script>
    tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          colors: {
            brand: { 50: '#f0f9ff', 500: '#0ea5e9', 600: '#0284c7', 900: '#0c4a6e' }
          }
        }
      }
    }
  </script>
  <style>
    #network-canvas { width: 100%; height: 640px; border-radius: 0.75rem; }
    .tab-content { display: none; }
    .tab-content.active { display: block; }
    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-track { background: #0b0f19; }
    ::-webkit-scrollbar-thumb { background: #1e293b; border-radius: 3px; }
    ::-webkit-scrollbar-thumb:hover { background: #334155; }
    
    .filter-btn.active {
      background-color: #0284c7;
      color: #ffffff;
      border-color: #38bdf8;
      box-shadow: 0 0 12px rgba(14, 165, 233, 0.3);
    }

    /* Estilos Premium para Markdown y Prosa Técnica */
    .prose, .prose-invert {
      color: #cbd5e1;
      max-width: 100% !important;
      width: 100% !important;
      font-size: 0.8125rem;
      line-height: 1.65;
    }
    .prose h1, .prose h2, .prose h3, .prose h4 {
      color: #f8fafc;
      font-weight: 700;
      margin-top: 1.25rem;
      margin-bottom: 0.5rem;
      letter-spacing: -0.015em;
    }
    .prose h1 {
      font-size: 1.25rem;
      border-bottom: 1px solid #1e293b;
      padding-bottom: 0.4rem;
      color: #38bdf8;
    }
    .prose h2 {
      font-size: 1.05rem;
      border-bottom: 1px solid #1e293b;
      padding-bottom: 0.3rem;
      color: #7dd3fc;
      margin-top: 1.5rem;
    }
    .prose h3 {
      font-size: 0.925rem;
      color: #93c5fd;
      margin-top: 1.1rem;
    }
    .prose h4 {
      font-size: 0.85rem;
      color: #cbd5e1;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .prose p {
      margin-top: 0.5rem;
      margin-bottom: 0.6rem;
    }
    .prose strong {
      color: #f1f5f9;
      font-weight: 600;
    }
    .prose ul, .prose ol {
      margin-top: 0.4rem;
      margin-bottom: 0.6rem;
      padding-left: 1.35rem;
    }
    .prose ul { list-style-type: disc; }
    .prose ol { list-style-type: decimal; }
    .prose li {
      margin-top: 0.2rem;
      margin-bottom: 0.2rem;
    }
    .prose blockquote {
      border-left: 3px solid #0ea5e9;
      background: rgba(14, 165, 233, 0.07);
      padding: 0.65rem 0.95rem;
      border-radius: 0 0.5rem 0.5rem 0;
      color: #94a3b8;
      margin: 0.85rem 0;
      font-style: normal;
    }
    .prose blockquote strong {
      color: #38bdf8;
    }
    .prose hr {
      border-color: #1e293b;
      margin: 1.25rem 0;
    }
    .prose table {
      width: 100% !important;
      max-width: 100% !important;
      table-layout: auto;
      border-collapse: separate;
      border-spacing: 0;
      margin: 0.85rem 0;
      border-radius: 0.6rem;
      overflow: hidden;
      border: 1px solid #1e293b;
      font-size: 0.775rem;
    }
    .prose th {
      background: #090d16;
      color: #38bdf8;
      font-weight: 700;
      text-align: left;
      padding: 0.6rem 0.85rem;
      border-bottom: 1px solid #1e293b;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      font-size: 0.7rem;
    }
    .prose td {
      padding: 0.55rem 0.85rem;
      border-bottom: 1px solid #111827;
      color: #cbd5e1;
    }
    .prose tr:last-child td {
      border-bottom: none;
    }
    .prose tbody tr:nth-child(even) {
      background: rgba(15, 23, 42, 0.45);
    }
    .prose tbody tr:hover {
      background: rgba(30, 41, 59, 0.6);
    }
    .prose code {
      background: #090e17;
      color: #38bdf8;
      padding: 0.15rem 0.4rem;
      border-radius: 0.35rem;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 0.75rem;
      border: 1px solid #1e293b;
    }
    .prose pre {
      background: #050811;
      border: 1px solid #1e293b;
      padding: 0.85rem;
      border-radius: 0.6rem;
      overflow-x: auto;
      margin: 0.85rem 0;
    }
    .prose pre code {
      background: transparent;
      padding: 0;
      border: none;
      color: #e2e8f0;
      font-size: 0.75rem;
    }

    /* Modal Animation */
    @keyframes modalFadeIn {
      from { opacity: 0; transform: scale(0.97) translateY(10px); }
      to { opacity: 1; transform: scale(1) translateY(0); }
    }
    .animate-modal {
      animation: modalFadeIn 0.18s cubic-bezier(0.16, 1, 0.3, 1) forwards;
    }
  </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen font-sans antialiased">
  <!-- Navbar con Datos del Proyecto -->
  <header class="border-b border-slate-800/80 bg-slate-900/90 backdrop-blur-md sticky top-0 z-50">
    <div class="w-full max-w-[1600px] mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
      <!-- Project Info Brand -->
      <div class="flex items-center gap-3 min-w-0">
        <div class="flex-shrink-0 w-8 h-8 flex items-center justify-center">
          <svg class="w-8 h-8" viewBox="0 0 240 240" fill="none" xmlns="http://www.w3.org/2000/svg">
            <line x1="120" y1="36" x2="35" y2="195" stroke="#38bdf8" stroke-width="6" stroke-linecap="round"/>
            <line x1="120" y1="54" x2="48" y2="195" stroke="#0284c7" stroke-width="4.5" stroke-linecap="round" opacity="0.85"/>
            <line x1="120" y1="36" x2="205" y2="195" stroke="#38bdf8" stroke-width="6" stroke-linecap="round"/>
            <line x1="120" y1="54" x2="192" y2="195" stroke="#0284c7" stroke-width="4.5" stroke-linecap="round" opacity="0.85"/>
            <polygon points="120,22 112,35 128,35" fill="#38bdf8"/>
            <line x1="78" y1="120" x2="108" y2="120" stroke="#34d399" stroke-width="5" stroke-linecap="round"/>
            <line x1="78" y1="128" x2="108" y2="128" stroke="#34d399" stroke-width="5" stroke-linecap="round"/>
            <line x1="132" y1="120" x2="162" y2="120" stroke="#34d399" stroke-width="5" stroke-linecap="round"/>
            <line x1="132" y1="128" x2="162" y2="128" stroke="#34d399" stroke-width="5" stroke-linecap="round"/>
            <circle cx="78" cy="124" r="10" fill="#34d399" stroke="#065f46" stroke-width="3"/>
            <circle cx="162" cy="124" r="10" fill="#34d399" stroke="#065f46" stroke-width="3"/>
            <polygon points="120,111 133,124 120,137 107,124" fill="#a855f7" stroke="#e9d5ff" stroke-width="2"/>
            <line x1="35" y1="191" x2="205" y2="191" stroke="#34d399" stroke-width="6" stroke-linecap="round"/>
            <line x1="35" y1="199" x2="205" y2="199" stroke="#34d399" stroke-width="6" stroke-linecap="round"/>
            <circle cx="35" cy="195" r="12" fill="#34d399" stroke="#065f46" stroke-width="3"/>
            <circle cx="205" cy="195" r="12" fill="#34d399" stroke="#065f46" stroke-width="3"/>
          </svg>
        </div>
        <div class="min-w-0">
          <div class="flex items-center gap-2 flex-wrap">
            <h1 id="nav-project-name" class="text-base sm:text-lg font-black bg-gradient-to-r from-sky-400 via-indigo-300 to-teal-300 bg-clip-text text-transparent truncate">Abbia OS</h1>
            <span id="nav-project-status" class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 flex-shrink-0">Activo</span>
          </div>
          <p id="nav-project-subtitle" class="text-[11px] text-slate-400 flex items-center gap-1.5 truncate">
            <span id="nav-project-type" class="truncate font-medium text-slate-300">Software</span>
            <span class="text-slate-600">•</span>
            <span id="nav-project-repo" class="font-mono text-slate-400 text-[10px] truncate">repo</span>
            <span class="text-slate-600">•</span>
            <span id="nav-project-path" class="font-mono text-slate-500 text-[10px] truncate"></span>
          </p>
        </div>
      </div>

      <!-- Navigation Tabs & About Button -->
      <div class="flex items-center gap-2 flex-shrink-0">
        <nav class="flex space-x-1 bg-slate-800/60 p-1 rounded-xl border border-slate-700/50 overflow-x-auto">
          <button onclick="switchTab('project')" id="tab-btn-project" class="tab-btn px-3 py-1.5 text-xs font-semibold rounded-lg transition-all text-slate-400 hover:text-slate-200">🏢 Proyecto</button>
          <button onclick="switchTab('features')" id="tab-btn-features" class="tab-btn px-3 py-1.5 text-xs font-semibold rounded-lg transition-all bg-sky-500 text-white shadow-lg shadow-sky-500/20">🚀 Iniciativas</button>
          <button onclick="switchTab('graph')" id="tab-btn-graph" class="tab-btn px-3 py-1.5 text-xs font-semibold rounded-lg transition-all text-slate-400 hover:text-slate-200">🕸️ Arquitectura ADR</button>
          <button onclick="switchTab('rules')" id="tab-btn-rules" class="tab-btn px-3 py-1.5 text-xs font-semibold rounded-lg transition-all text-slate-400 hover:text-slate-200">⚖️ Reglas</button>
          <button onclick="switchTab('memory')" id="tab-btn-memory" class="tab-btn px-3 py-1.5 text-xs font-semibold rounded-lg transition-all text-slate-400 hover:text-slate-200">🧠 Memoria</button>
          <button onclick="switchTab('metrics')" id="tab-btn-metrics" class="tab-btn px-3 py-1.5 text-xs font-semibold rounded-lg transition-all text-slate-400 hover:text-slate-200">📊 Telemetría</button>
        </nav>
        <button onclick="location.reload()" id="btn-live-reload" class="px-2.5 py-1.5 text-xs font-medium rounded-xl text-slate-300 hover:text-white bg-slate-800/90 hover:bg-slate-700 border border-slate-700/70 shadow-sm flex items-center gap-1.5 transition" title="Recargar Dashboard (F5)">
          <span id="live-indicator-dot" class="inline-block w-2 h-2 rounded-full bg-slate-500"></span>
          <span id="live-indicator-text" class="hidden sm:inline text-[11px] font-semibold">Recargar</span>
        </button>
        <button onclick="openAboutModal()" class="px-3 py-1.5 text-xs font-semibold rounded-xl text-slate-300 hover:text-white bg-slate-800/90 hover:bg-slate-700 border border-slate-700/70 shadow-sm flex items-center gap-1.5 transition" title="Acerca de Abbia OS">
          <span>ℹ️</span> <span class="hidden md:inline text-[11px] font-bold bg-gradient-to-r from-sky-400 to-indigo-300 bg-clip-text text-transparent">About</span>
        </button>
      </div>
    </div>
  </header>

  <!-- Main Container -->
  <main class="w-full max-w-[1600px] mx-auto px-4 sm:px-6 lg:px-8 py-6">
HTML_HEADER

# Inyectar datos en el HTML como scripts JSON seguros
cat << HTML_DATA >> "$OUTPUT_HTML"
  <!-- Raw Data Payload -->
  <script type="application/json" id="raw-project">
$PROJECT_META_JSON
  </script>
  <script type="text/plain" id="raw-context">
$CONTEXT_RAW
  </script>
  <script type="text/plain" id="raw-kg">
$KG_RAW
  </script>
  <script type="text/plain" id="raw-metrics">
$METRICS_RAW
  </script>
  <script type="text/plain" id="raw-log">
$LOG_RAW
  </script>
  <script type="text/plain" id="raw-catalog">
$CATALOG_RAW
  </script>
  <script type="text/plain" id="raw-patterns">
$PATTERNS_RAW
  </script>
  <script type="text/plain" id="raw-snapshot">
$SNAPSHOT_RAW
  </script>
  <script type="text/plain" id="raw-rules">
$RULES_RAW
  </script>
  <script type="text/plain" id="raw-glossary">
$GLOSSARY_RAW
  </script>
  <script type="application/json" id="raw-initiatives">
$INITIATIVES_RAW
  </script>
HTML_DATA

cat << 'HTML_BODY' >> "$OUTPUT_HTML"
    <!-- ==================== TAB 0: DATOS DEL PROYECTO & CONTEXTO ==================== -->
    <section id="tab-project" class="tab-content space-y-6">
      <!-- Project Hero Card -->
      <div class="bg-gradient-to-br from-slate-900 via-slate-900 to-slate-950 border border-slate-800/80 rounded-2xl p-6 sm:p-7 shadow-xl relative overflow-hidden">
        <div class="absolute -top-12 -right-12 w-72 h-72 bg-sky-500/10 rounded-full blur-3xl pointer-events-none"></div>
        <div class="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div class="space-y-3 flex-1 min-w-0">
            <div class="flex items-center gap-2.5 flex-wrap">
              <span id="hero-project-type-badge" class="px-3 py-0.5 rounded-full text-xs font-bold bg-sky-500/20 text-sky-300 border border-sky-500/30">SaaS</span>
              <span id="hero-project-status-badge" class="px-3 py-0.5 rounded-full text-xs font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">En producción</span>
              <span class="text-xs text-slate-500">Última actualización: <span id="hero-project-updated" class="text-slate-300 font-mono font-medium">2026-09-12</span></span>
            </div>
            <h2 id="hero-project-title" class="text-2xl sm:text-3xl font-black text-slate-100 tracking-tight">Nombre del Proyecto</h2>
            <p id="hero-project-desc" class="text-xs sm:text-sm text-slate-300 leading-relaxed">Descripción general y objetivos del proyecto.</p>
          </div>
          
          <div class="flex flex-col sm:flex-row md:flex-col gap-2.5 flex-shrink-0 justify-center">
            <button onclick="copyToClipboard(projectMeta.root, 'Ruta del proyecto copiada al portapapeles')" class="inline-flex items-center justify-center gap-2 px-4 py-2 bg-slate-800/90 hover:bg-slate-700 text-xs font-semibold text-slate-200 rounded-xl border border-slate-700 transition shadow-sm">
              <span>📁</span>
              <span>Copiar Ruta Local</span>
            </button>
            <a id="hero-project-repo-link" href="#" target="_blank" class="inline-flex items-center justify-center gap-2 px-4 py-2 bg-slate-800/90 hover:bg-slate-700 text-xs font-semibold text-slate-200 rounded-xl border border-slate-700 transition shadow-sm">
              <span>🌐</span>
              <span id="hero-project-repo-text">Ver Repositorio</span>
            </a>
            <button onclick="switchTab('features')" class="inline-flex items-center justify-center gap-2 px-4 py-2 bg-sky-600 hover:bg-sky-500 text-xs font-semibold text-white rounded-xl transition shadow-lg shadow-sky-600/20">
              <span>🚀</span>
              <span>Explorar Iniciativas</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Quick Metadata Grid -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-slate-900/90 border border-slate-800/80 p-5 rounded-2xl flex items-start gap-3.5 shadow-sm">
          <div class="w-10 h-10 rounded-xl bg-sky-500/10 border border-sky-500/20 flex items-center justify-center text-xl flex-shrink-0">🏢</div>
          <div class="min-w-0">
            <div class="text-[11px] font-medium text-slate-400">Tipo de Aplicación</div>
            <div id="meta-project-type" class="text-xs font-bold text-slate-200 mt-0.5 truncate">-</div>
          </div>
        </div>

        <div class="bg-slate-900/90 border border-slate-800/80 p-5 rounded-2xl flex items-start gap-3.5 shadow-sm">
          <div class="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-xl flex-shrink-0">🏷️</div>
          <div class="min-w-0">
            <div class="text-[11px] font-medium text-slate-400">Estado del Proyecto</div>
            <div id="meta-project-status" class="text-xs font-bold text-emerald-400 mt-0.5 truncate">-</div>
          </div>
        </div>

        <div class="bg-slate-900/90 border border-slate-800/80 p-5 rounded-2xl flex items-start gap-3.5 shadow-sm">
          <div class="w-10 h-10 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center text-xl flex-shrink-0">📁</div>
          <div class="min-w-0">
            <div class="text-[11px] font-medium text-slate-400">Ruta Raíz Local</div>
            <div id="meta-project-path" class="text-xs font-mono font-semibold text-slate-300 mt-0.5 truncate cursor-pointer hover:text-sky-400 transition" onclick="copyToClipboard(projectMeta.root, 'Ruta copiada')" title="Clic para copiar">-</div>
          </div>
        </div>

        <div class="bg-slate-900/90 border border-slate-800/80 p-5 rounded-2xl flex items-start gap-3.5 shadow-sm">
          <div class="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-xl flex-shrink-0">🤖</div>
          <div class="min-w-0">
            <div class="text-[11px] font-medium text-slate-400">Framework AI</div>
            <div class="text-xs font-bold text-amber-300 mt-0.5 flex items-center gap-1.5">
              <span>Abbia OS v4.0.0</span>
              <button onclick="openAboutModal()" class="text-[10px] bg-amber-500/20 text-amber-300 px-1.5 py-0.2 rounded hover:bg-amber-500/30 transition">ℹ️</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Project Sub-Tabs Navigation Bar -->
      <div class="bg-slate-900/90 border border-slate-800/80 rounded-2xl p-2 flex items-center gap-2 overflow-x-auto text-xs shadow-sm">
        <button onclick="switchProjectSubTab('goals')" id="btn-project-sub-goals" class="project-subtab-btn px-4 py-2 rounded-xl font-semibold bg-sky-500 text-white shadow-sm transition flex items-center gap-2 flex-shrink-0">
          <span>🎯</span> Objetivos de Negocio (§2)
        </button>
        <button onclick="switchProjectSubTab('actors')" id="btn-project-sub-actors" class="project-subtab-btn px-4 py-2 rounded-xl font-semibold text-slate-400 hover:text-slate-200 transition flex items-center gap-2 flex-shrink-0">
          <span>👥</span> Usuarios & Actores (§3)
        </button>
        <button onclick="switchProjectSubTab('stack')" id="btn-project-sub-stack" class="project-subtab-btn px-4 py-2 rounded-xl font-semibold text-slate-400 hover:text-slate-200 transition flex items-center gap-2 flex-shrink-0">
          <span>⚡</span> Stack Tecnológico (§4)
        </button>
        <button onclick="switchProjectSubTab('meta')" id="btn-project-sub-meta" class="project-subtab-btn px-4 py-2 rounded-xl font-semibold text-slate-400 hover:text-slate-200 transition flex items-center gap-2 flex-shrink-0">
          <span>📋</span> Ficha Técnica & Entorno
        </button>
        <button onclick="switchProjectSubTab('context')" id="btn-project-sub-context" class="project-subtab-btn px-4 py-2 rounded-xl font-semibold text-slate-400 hover:text-slate-200 transition flex items-center gap-2 flex-shrink-0">
          <span>📖</span> Memoria Permanente (.abbia/context.md)
        </button>
      </div>

      <!-- Sub-Tab Content Panels (Full Width, Zero Horizontal Scroll!) -->
      <div id="project-subpanel-goals" class="project-subpanel bg-slate-900/90 border border-slate-800/80 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <h3 class="text-xs font-bold text-sky-400 uppercase tracking-wider flex items-center gap-2">
            <span>🎯</span> Objetivos de Negocio del Producto
          </h3>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded font-mono">.abbia/context.md (§2)</span>
        </div>
        <div id="project-goals-content" class="prose prose-invert max-w-none w-full mt-4"></div>
      </div>

      <div id="project-subpanel-actors" class="project-subpanel hidden bg-slate-900/90 border border-slate-800/80 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <h3 class="text-xs font-bold text-indigo-400 uppercase tracking-wider flex items-center gap-2">
            <span>👥</span> Matriz de Usuarios, Actores & Permisos
          </h3>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded font-mono">.abbia/context.md (§3)</span>
        </div>
        <div id="project-actors-content" class="prose prose-invert max-w-none w-full mt-4"></div>
      </div>

      <div id="project-subpanel-stack" class="project-subpanel hidden bg-slate-900/90 border border-slate-800/80 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <h3 class="text-xs font-bold text-emerald-400 uppercase tracking-wider flex items-center gap-2">
            <span>⚡</span> Arquitectura & Stack Tecnológico
          </h3>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded font-mono">.abbia/context.md (§4)</span>
        </div>
        <div id="project-stack-content" class="prose prose-invert max-w-none w-full mt-4"></div>
      </div>

      <div id="project-subpanel-meta" class="project-subpanel hidden bg-slate-900/90 border border-slate-800/80 rounded-2xl p-6 shadow-sm space-y-6">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center gap-2">
            <span>📋</span> Ficha Técnica del Proyecto & Configuración
          </h3>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded font-mono">Abbia OS</span>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div class="bg-slate-950/70 p-4 rounded-xl border border-slate-800/80 space-y-1">
            <span class="text-slate-500 block text-[10px] uppercase font-semibold">Repositorio Git</span>
            <span id="meta-detail-repo" class="font-mono text-slate-200 text-xs font-semibold break-all">-</span>
          </div>
          <div class="bg-slate-950/70 p-4 rounded-xl border border-slate-800/80 space-y-1">
            <span class="text-slate-500 block text-[10px] uppercase font-semibold">Ruta Local del Workspace</span>
            <span id="meta-detail-path" class="font-mono text-slate-300 text-xs break-all">-</span>
          </div>
          <div class="bg-slate-950/70 p-4 rounded-xl border border-slate-800/80 space-y-1">
            <span class="text-slate-500 block text-[10px] uppercase font-semibold">Submódulo Framework</span>
            <div class="flex items-center justify-between">
              <span class="font-mono text-sky-400 text-xs">.abbia/core/ (Abbia OS)</span>
              <button onclick="openAboutModal()" class="text-[10px] bg-sky-500/20 text-sky-300 px-2 py-0.5 rounded-md hover:bg-sky-500/30 transition">Info</button>
            </div>
          </div>
          <div class="bg-slate-950/70 p-4 rounded-xl border border-slate-800/80 space-y-1">
            <span class="text-slate-500 block text-[10px] uppercase font-semibold">Directorio de Iniciativas</span>
            <span class="font-mono text-indigo-400 text-xs">.abbia/initiatives/ & .abbia/archive/</span>
          </div>
          <div class="bg-slate-950/70 p-4 rounded-xl border border-slate-800/80 space-y-1">
            <span class="text-slate-500 block text-[10px] uppercase font-semibold">Memoria Técnica Persistente</span>
            <span class="font-mono text-emerald-400 text-xs">.abbia/memory/</span>
          </div>
          <div class="bg-slate-950/70 p-4 rounded-xl border border-slate-800/80 space-y-1">
            <span class="text-slate-500 block text-[10px] uppercase font-semibold">Telemetría de Agentes</span>
            <span class="font-mono text-amber-400 text-xs">.abbia/metrics/executions.yaml</span>
          </div>
        </div>
      </div>

      <div id="project-subpanel-context" class="project-subpanel hidden bg-slate-900/90 border border-slate-800/80 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <div>
            <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center gap-2">
              <span>📖</span> Documento Maestro de Contexto
            </h3>
            <p class="text-[11px] text-slate-400 mt-0.5">Documento fuente de verdad que consumen todos los roles de agentes.</p>
          </div>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded font-mono">.ai/context.md</span>
        </div>
        <div id="project-context-full-content" class="prose prose-invert max-w-none w-full mt-4 max-h-[700px] overflow-y-auto pr-2"></div>
      </div>
    </section>

    <!-- ==================== TAB 1: INICIATIVAS & PIPELINE SDD ==================== -->
    <section id="tab-features" class="tab-content active space-y-6">
      <!-- Quick Summary Cards -->
      <div class="grid grid-cols-2 sm:grid-cols-6 gap-3">
        <div class="bg-slate-900/90 border border-slate-800/80 p-4 rounded-2xl shadow-sm">
          <div class="text-[11px] text-slate-400 font-medium">Iniciativas Totales</div>
          <div id="init-kpi-total" class="text-xl sm:text-2xl font-black text-sky-400 mt-1">0</div>
        </div>
        <div class="bg-slate-900/90 border border-slate-800/80 p-4 rounded-2xl shadow-sm">
          <div class="text-[11px] text-slate-400 font-medium">Activas (.ai/features)</div>
          <div id="init-kpi-active" class="text-xl sm:text-2xl font-black text-emerald-400 mt-1">0</div>
        </div>
        <div class="bg-slate-900/90 border border-slate-800/80 p-4 rounded-2xl shadow-sm">
          <div class="text-[11px] text-slate-400 font-medium">Archivadas (.ai/archive)</div>
          <div id="init-kpi-archived" class="text-xl sm:text-2xl font-black text-slate-400 mt-1">0</div>
        </div>
        <div class="bg-slate-900/90 border border-slate-800/80 p-4 rounded-2xl shadow-sm">
          <div class="text-[11px] text-slate-400 font-medium">Features (FEAT)</div>
          <div id="init-kpi-feats" class="text-xl sm:text-2xl font-black text-sky-300 mt-1">0</div>
        </div>
        <div class="bg-slate-900/90 border border-slate-800/80 p-4 rounded-2xl shadow-sm">
          <div class="text-[11px] text-slate-400 font-medium">Bugs (BUG)</div>
          <div id="init-kpi-bugs" class="text-xl sm:text-2xl font-black text-rose-400 mt-1">0</div>
        </div>
        <div class="bg-slate-900/90 border border-slate-800/80 p-4 rounded-2xl shadow-sm">
          <div class="text-[11px] text-slate-400 font-medium">QA Aprobado</div>
          <div id="init-kpi-approved" class="text-xl sm:text-2xl font-black text-teal-400 mt-1">0</div>
        </div>
      </div>

      <!-- Advanced Filter & Search Toolbar -->
      <div class="bg-slate-900/90 p-4 sm:p-5 rounded-2xl border border-slate-800/80 space-y-4 shadow-sm">
        <div class="flex flex-col md:flex-row items-center justify-between gap-3">
          <!-- Live Text Search -->
          <div class="relative w-full md:w-96">
            <span class="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-500 text-xs">🔍</span>
            <input type="text" id="init-search-input" oninput="applyInitiativeFilters()" placeholder="Buscar por ID, título o palabra clave..." class="w-full bg-slate-950 border border-slate-700/80 rounded-xl pl-9 pr-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-sky-500 placeholder:text-slate-600 transition">
          </div>

          <!-- Sort Selector -->
          <div class="flex items-center gap-2 w-full md:w-auto justify-end">
            <span class="text-xs text-slate-400">Ordenar:</span>
            <select id="init-sort-select" onchange="applyInitiativeFilters()" class="bg-slate-950 border border-slate-700/80 text-xs text-slate-200 rounded-xl px-3 py-1.5 focus:outline-none focus:border-sky-500 transition">
              <option value="id-asc">ID (A - Z)</option>
              <option value="id-desc">ID (Z - A)</option>
              <option value="tokens-desc">Más tokens registrados</option>
              <option value="tokens-asc">Menos tokens registrados</option>
              <option value="title-asc">Título (A - Z)</option>
            </select>
          </div>
        </div>

        <!-- Filter Pill Buttons -->
        <div class="flex flex-wrap items-center justify-between gap-3 pt-3 border-t border-slate-800/80 text-xs">
          <!-- Type Filter -->
          <div class="flex items-center gap-1.5 flex-wrap">
            <span class="text-[11px] font-semibold text-slate-400 mr-1">Tipo:</span>
            <button onclick="setTypeFilter('ALL')" id="filter-type-ALL" class="filter-type-btn filter-btn active px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">Todos</button>
            <button onclick="setTypeFilter('FEAT')" id="filter-type-FEAT" class="filter-type-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">FEAT</button>
            <button onclick="setTypeFilter('BUG')" id="filter-type-BUG" class="filter-type-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">BUG</button>
            <button onclick="setTypeFilter('AUDIT')" id="filter-type-AUDIT" class="filter-type-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">AUDIT</button>
            <button onclick="setTypeFilter('REF')" id="filter-type-REF" class="filter-type-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">REF</button>
          </div>

          <!-- Status Filter -->
          <div class="flex items-center gap-1.5 flex-wrap">
            <span class="text-[11px] font-semibold text-slate-400 mr-1">Estado:</span>
            <button onclick="setStatusFilter('ALL')" id="filter-status-ALL" class="filter-status-btn filter-btn active px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">Todas</button>
            <button onclick="setStatusFilter('ACTIVE')" id="filter-status-ACTIVE" class="filter-status-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">Activas</button>
            <button onclick="setStatusFilter('ARCHIVED')" id="filter-status-ARCHIVED" class="filter-status-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">Archivadas</button>
            <button onclick="setStatusFilter('READY_TO_ARCHIVE')" id="filter-status-READY_TO_ARCHIVE" class="filter-status-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-amber-500/40 bg-amber-500/10 text-amber-300 hover:bg-amber-500/20 transition">📦 Listas para Archivar</button>
          </div>

          <!-- QA Status Filter -->
          <div class="flex items-center gap-1.5 flex-wrap">
            <span class="text-[11px] font-semibold text-slate-400 mr-1">QA:</span>
            <button onclick="setQaFilter('ALL')" id="filter-qa-ALL" class="filter-qa-btn filter-btn active px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">Todos</button>
            <button onclick="setQaFilter('APROBADO')" id="filter-qa-APROBADO" class="filter-qa-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">🟢 Aprobado</button>
            <button onclick="setQaFilter('PENDING')" id="filter-qa-PENDING" class="filter-qa-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700/70 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">🟡 Pendiente</button>
          </div>
        </div>
      </div>

      <!-- Counter feedback -->
      <div class="flex items-center justify-between text-xs text-slate-400 px-1">
        <span id="initiatives-count-label" class="font-medium text-slate-300">Mostrando 0 iniciativas</span>
      </div>

      <!-- Initiatives Responsive Cards Grid -->
      <div id="initiatives-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5"></div>

      <!-- Pagination Controls -->
      <div id="initiatives-pagination" class="bg-slate-900/80 border border-slate-800/80 rounded-2xl p-4 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs shadow-sm">
        <div class="flex items-center gap-3 text-slate-400">
          <span id="pagination-info" class="font-medium text-slate-300">Página 1 de 1</span>
          <span class="text-slate-700">•</span>
          <div class="flex items-center gap-1.5">
            <span>Por página:</span>
            <select id="init-page-size-select" onchange="changePageSize(this.value)" class="bg-slate-950 border border-slate-700/80 text-xs text-slate-200 rounded-lg px-2.5 py-1 focus:outline-none focus:border-sky-500">
              <option value="12" selected>12</option>
              <option value="24">24</option>
              <option value="48">48</option>
              <option value="all">Todas</option>
            </select>
          </div>
        </div>

        <div id="pagination-buttons" class="flex items-center gap-1 flex-wrap justify-center"></div>
      </div>
    </section>

    <!-- ==================== TAB 2: KNOWLEDGE GRAPH (ADR) ==================== -->
    <section id="tab-graph" class="tab-content space-y-4">
      <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 bg-slate-900/60 p-5 rounded-2xl border border-slate-800">
        <div>
          <h2 class="text-base font-semibold text-slate-200 flex items-center gap-2 flex-wrap">
            <span>🕸️</span> Decisiones Arquitectónicas (ADRs) & Knowledge Graph
            <span id="graph-node-count" class="px-2.5 py-0.5 rounded-full bg-slate-800 text-sky-400 text-[10px] font-mono border border-slate-700">0 decisiones</span>
          </h2>
          <p class="text-xs text-slate-400 mt-0.5">Explora dependencias, reemplazos, matriz de decisiones e impacto técnico.</p>
        </div>
        
        <div class="flex items-center gap-3 w-full md:w-auto flex-wrap">
          <!-- View Mode Toggle -->
          <div class="flex bg-slate-950 p-1 rounded-xl border border-slate-800 text-xs font-medium">
            <button id="btn-graph-mode-canvas" onclick="setGraphViewMode('canvas')" class="px-3 py-1.5 rounded-lg bg-sky-500 text-white font-semibold shadow-sm transition flex items-center gap-1.5">
              <span>🕸️</span> Grafo 2D
            </button>
            <button id="btn-graph-mode-matrix" onclick="setGraphViewMode('matrix')" class="px-3 py-1.5 rounded-lg text-slate-400 hover:text-slate-200 transition flex items-center gap-1.5">
              <span>📑</span> Catálogo ADR
            </button>
          </div>

          <div class="relative flex-1 md:w-56">
            <input type="text" id="graph-search" oninput="filterGraph(this.value)" placeholder="Buscar por ID o título..." class="w-full bg-slate-950 border border-slate-700/80 rounded-xl pl-8 pr-3 py-1.5 text-xs text-slate-200 focus:outline-none focus:border-sky-500">
            <span class="absolute left-2.5 top-2 text-slate-500 text-xs">🔍</span>
          </div>
        </div>
      </div>

      <!-- Filter Chips & Zoom Bar -->
      <div class="flex items-center justify-between gap-3 flex-wrap bg-slate-900/40 px-4 py-2.5 rounded-xl border border-slate-800/80 text-xs">
        <div class="flex items-center gap-2 flex-wrap">
          <span class="text-slate-500 text-[11px] uppercase tracking-wider font-semibold">Filtrar:</span>
          <button onclick="setGraphTypeFilter('ALL')" id="filter-graph-all" class="graph-filter-chip px-3 py-1 rounded-lg text-xs font-medium bg-sky-500 text-white border border-sky-400/30 transition">Todas (<span id="count-graph-all">0</span>)</button>
          <button onclick="setGraphTypeFilter('FEAT')" id="filter-graph-feat" class="graph-filter-chip px-3 py-1 rounded-lg text-xs font-medium bg-slate-800/80 text-slate-300 hover:bg-slate-700 border border-slate-700 transition">🚀 Features (<span id="count-graph-feat">0</span>)</button>
          <button onclick="setGraphTypeFilter('BUG')" id="filter-graph-bug" class="graph-filter-chip px-3 py-1 rounded-lg text-xs font-medium bg-slate-800/80 text-slate-300 hover:bg-slate-700 border border-slate-700 transition">🐛 Bugs (<span id="count-graph-bug">0</span>)</button>
        </div>
        <div id="graph-zoom-toolbar" class="flex items-center gap-1.5">
          <button onclick="zoomGraph(1.3)" class="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg border border-slate-700 text-xs" title="Zoom in">➕</button>
          <button onclick="zoomGraph(0.75)" class="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg border border-slate-700 text-xs" title="Zoom out">➖</button>
          <button onclick="setGraphZoom100()" class="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg border border-slate-700 text-xs font-medium" title="Vista 100% legible">100%</button>
          <button onclick="resetGraphView()" class="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg border border-slate-700 text-xs font-medium" title="Ajustar todo en pantalla">🎯 Ajustar</button>
          <button onclick="reorganizeGraphGrid()" class="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg border border-slate-700 text-xs font-medium" title="Ordenar en cuadrícula limpia">📐 Cuadrícula</button>
        </div>
      </div>

      <!-- Graph 2D View -->
      <div id="graph-view-canvas" class="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <div class="lg:col-span-3 bg-slate-900 border border-slate-800 rounded-2xl relative overflow-hidden shadow-inner">
          <div id="network-canvas"></div>
          <!-- Legend Overlay -->
          <div class="absolute bottom-3 left-3 bg-slate-950/90 border border-slate-800/80 p-3 rounded-xl text-xs space-y-1.5 backdrop-blur-md">
            <div class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Leyenda</div>
            <div class="flex items-center gap-2"><span class="w-3 h-3 rounded-md bg-[#0f172a] border-2 border-emerald-400 inline-block"></span> <span>Activo (ACTIVE)</span></div>
            <div class="flex items-center gap-2"><span class="w-3 h-3 rounded-md bg-[#0f172a] border-2 border-amber-400 inline-block"></span> <span>Propuesta (PENDING)</span></div>
            <div class="flex items-center gap-2"><span class="w-3 h-3 rounded-md bg-[#0f172a] border-2 border-slate-500 inline-block"></span> <span>Reemplazado (SUPERSEDED)</span></div>
            <div class="flex items-center gap-2"><span class="w-3 h-0.5 bg-sky-400 inline-block"></span> <span>depends_on</span></div>
            <div class="flex items-center gap-2"><span class="w-3 h-0.5 bg-rose-400 inline-block"></span> <span>conflicts_with</span></div>
          </div>
        </div>

        <!-- Node Detail Side Panel -->
        <div class="bg-slate-900 border border-slate-800 rounded-2xl p-5 flex flex-col justify-between min-h-[450px]">
          <div id="node-detail-empty" class="text-center py-24 text-slate-500">
            <span class="text-3xl">👈</span>
            <p class="mt-2 text-xs">Haz clic en cualquier nodo o tarjeta para ver el detalle de la decisión arquitectónica.</p>
          </div>
          <div id="node-detail-card" class="hidden space-y-4">
            <div class="flex items-center justify-between">
              <span id="detail-id" class="font-mono text-sm font-bold text-sky-400">ARCH-001</span>
              <span id="detail-status" class="px-2 py-0.5 rounded text-[10px] font-semibold">ACTIVE</span>
            </div>
            <div>
              <h3 id="detail-title" class="text-sm font-bold text-slate-100 leading-snug">Título de la Decisión</h3>
            </div>
            <div class="border-t border-slate-800 pt-3 space-y-2 text-xs">
              <div>
                <span class="text-slate-400 block font-medium">Depende de:</span>
                <div id="detail-depends" class="mt-1 font-mono text-slate-300">-</div>
              </div>
              <div>
                <span class="text-slate-400 block font-medium">Reemplaza a:</span>
                <div id="detail-supersedes" class="mt-1 font-mono text-slate-300">-</div>
              </div>
              <div>
                <span class="text-slate-400 block font-medium">Conflictos potenciales:</span>
                <div id="detail-conflicts" class="mt-1 font-mono text-rose-400">-</div>
              </div>
            </div>
          </div>
          <div class="mt-4 pt-3 border-t border-slate-800 text-[11px] text-slate-500">
            Fuente de verdad: <code class="text-slate-400">.ai/knowledge-graph.yaml</code>
          </div>
        </div>
      </div>

      <!-- Matrix / Catalog Mode -->
      <div id="graph-view-matrix" class="hidden space-y-4">
        <div id="adr-cards-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5 max-h-[640px] overflow-y-auto pr-2"></div>
      </div>
    </section>

    <!-- ==================== TAB 3: REGLAS DE NEGOCIO & GLOSARIO ==================== -->
    <section id="tab-rules" class="tab-content space-y-4">
      <!-- Sub-Tabs Navigation Bar -->
      <div class="bg-slate-900/90 border border-slate-800/80 rounded-2xl p-2 flex items-center justify-between gap-3 flex-wrap shadow-sm">
        <div class="flex items-center gap-2 text-xs">
          <button onclick="switchRulesSubTab('rules')" id="btn-rules-sub-rules" class="rules-subtab-btn px-4 py-2 rounded-xl font-semibold bg-sky-500 text-white shadow-sm transition flex items-center gap-2">
            <span>⚖️</span> Reglas de Negocio del Dominio
          </button>
          <button onclick="switchRulesSubTab('glossary')" id="btn-rules-sub-glossary" class="rules-subtab-btn px-4 py-2 rounded-xl font-semibold text-slate-400 hover:text-slate-200 transition flex items-center gap-2">
            <span>📖</span> Glosario de Términos
          </button>
        </div>
        <div class="text-[11px] text-slate-400 font-mono pr-3">
          <span id="rules-file-badge" class="px-2.5 py-1 rounded-lg bg-slate-950 border border-slate-800 text-sky-400">.ai/business-rules.md</span>
        </div>
      </div>

      <!-- Business Rules Panel (Full Width!) -->
      <div id="rules-subpanel-rules" class="rules-subpanel bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <div>
            <h3 class="text-xs font-bold text-sky-400 uppercase tracking-wider flex items-center gap-2">
              <span>⚖️</span> Reglas de Negocio del Dominio
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">Reglas formales activas que rigen la lógica y validaciones de la aplicación.</p>
          </div>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2.5 py-1 rounded font-mono">.ai/business-rules.md</span>
        </div>
        <div id="rules-content" class="prose prose-invert max-w-none w-full mt-4 max-h-[700px] overflow-y-auto pr-2"></div>
      </div>

      <!-- Glossary Panel (Full Width!) -->
      <div id="rules-subpanel-glossary" class="rules-subpanel hidden bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <div>
            <h3 class="text-xs font-bold text-indigo-400 uppercase tracking-wider flex items-center gap-2">
              <span>📖</span> Glosario de Términos & Conceptos Clave
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">Vocabulario ubicuo del dominio para evitar ambigüedades funcionales.</p>
          </div>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2.5 py-1 rounded font-mono">.ai/glossary.md</span>
        </div>
        <div id="glossary-content" class="prose prose-invert max-w-none w-full mt-4 max-h-[700px] overflow-y-auto pr-2"></div>
      </div>
    </section>

    <!-- ==================== TAB 4: WORKFLOW MEMORY & PATRONES ==================== -->
    <section id="tab-memory" class="tab-content space-y-4">
      <!-- Sub-Tabs Navigation Bar -->
      <div class="bg-slate-900/90 border border-slate-800/80 rounded-2xl p-2 flex items-center gap-2 overflow-x-auto text-xs shadow-sm">
        <button onclick="switchMemorySubTab('snapshot')" id="btn-memory-sub-snapshot" class="memory-subtab-btn px-4 py-2 rounded-xl font-semibold bg-sky-500 text-white shadow-sm transition flex items-center gap-2 flex-shrink-0">
          <span>🧠</span> Context Snapshot
        </button>
        <button onclick="switchMemorySubTab('log')" id="btn-memory-sub-log" class="memory-subtab-btn px-4 py-2 rounded-xl font-semibold text-slate-400 hover:text-slate-200 transition flex items-center gap-2 flex-shrink-0">
          <span>📜</span> Bitácora de Sesiones (Workflow Log)
        </button>
        <button onclick="switchMemorySubTab('catalog')" id="btn-memory-sub-catalog" class="memory-subtab-btn px-4 py-2 rounded-xl font-semibold text-slate-400 hover:text-slate-200 transition flex items-center gap-2 flex-shrink-0">
          <span>⚖️</span> Catálogo de Decisiones
        </button>
        <button onclick="switchMemorySubTab('patterns')" id="btn-memory-sub-patterns" class="memory-subtab-btn px-4 py-2 rounded-xl font-semibold text-slate-400 hover:text-slate-200 transition flex items-center gap-2 flex-shrink-0">
          <span>💡</span> Patrones & Lecciones Aprendidas
        </button>
      </div>

      <!-- Snapshot Panel -->
      <div id="memory-subpanel-snapshot" class="memory-subpanel bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <div>
            <h3 class="text-xs font-bold text-sky-400 uppercase tracking-wider flex items-center gap-2">
              <span>🧠</span> Context Snapshot (Memoria de Trabajo)
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">Estado operativo resumido para inyección rápida en prompts de agentes.</p>
          </div>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2.5 py-1 rounded font-mono">.ai/memory/context-snapshot.md</span>
        </div>
        <div id="snapshot-content" class="prose prose-invert max-w-none w-full mt-4 max-h-[700px] overflow-y-auto pr-2"></div>
      </div>

      <!-- Log Timeline Panel -->
      <div id="memory-subpanel-log" class="memory-subpanel hidden bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <div>
            <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center gap-2">
              <span>📜</span> Línea de Tiempo de Sesiones de Agentes
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">Registro cronológico episódico de tareas ejecutadas en el repositorio.</p>
          </div>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2.5 py-1 rounded font-mono">.ai/memory/workflow-log.md</span>
        </div>
        <div id="log-timeline" class="space-y-4 mt-4 max-h-[700px] overflow-y-auto pr-2"></div>
      </div>

      <!-- Catalog Panel -->
      <div id="memory-subpanel-catalog" class="memory-subpanel hidden bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <div>
            <h3 class="text-xs font-bold text-amber-400 uppercase tracking-wider flex items-center gap-2">
              <span>⚖️</span> Catálogo de Decisiones Técnicas
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">Memoria semántica de elecciones de diseño y acuerdos arquitectónicos.</p>
          </div>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2.5 py-1 rounded font-mono">.ai/memory/decisions-catalog.md</span>
        </div>
        <div id="catalog-content" class="prose prose-invert max-w-none w-full mt-4 max-h-[700px] overflow-y-auto pr-2"></div>
      </div>

      <!-- Patterns Panel -->
      <div id="memory-subpanel-patterns" class="memory-subpanel hidden bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-sm">
        <div class="flex items-center justify-between pb-3.5 border-b border-slate-800">
          <div>
            <h3 class="text-xs font-bold text-emerald-400 uppercase tracking-wider flex items-center gap-2">
              <span>💡</span> Patrones & Lecciones Aprendidas
            </h3>
            <p class="text-xs text-slate-400 mt-0.5">Memoria procedimental acumulada durante el ciclo de vida del proyecto.</p>
          </div>
          <span class="text-[10px] bg-slate-800 text-slate-400 px-2.5 py-1 rounded font-mono">.ai/memory/patterns-learned.md</span>
        </div>
        <div id="patterns-content" class="prose prose-invert max-w-none w-full mt-4 max-h-[700px] overflow-y-auto pr-2"></div>
      </div>
    </section>

    <!-- ==================== TAB 5: TELEMETRÍA DE AGENTES ==================== -->
    <section id="tab-metrics" class="tab-content space-y-6">
      <!-- Banner de estado vacío — visible solo si no hay tokens medidos -->
      <div id="metrics-empty-banner" class="hidden items-start gap-3 p-4 bg-amber-500/10 border border-amber-500/30 rounded-xl text-xs text-amber-300">
        <div class="text-xl mt-0.5">⚠️</div>
        <div>
          <div class="font-bold text-amber-200 mb-1">Sin telemetría real de tokens registrada</div>
          <div class="text-amber-300/80 leading-relaxed">
            Todas las entradas en <code class="bg-slate-800 px-1 py-0.5 rounded text-amber-400">.ai/metrics/executions.yaml</code> tienen <code class="bg-slate-800 px-1 py-0.5 rounded">tokens_in: null</code>.
            Para capturar tokens reales, pasá los flags al llamar <code class="bg-slate-800 px-1 py-0.5 rounded text-sky-400">finish-phase.sh</code>:
          </div>
          <pre class="mt-2 bg-slate-950/60 border border-slate-700/60 rounded-lg p-3 text-[10px] text-sky-300 overflow-x-auto">bash .ai/agents/scripts/finish-phase.sh &lt;INICIATIVA&gt; &lt;FASE&gt; &lt;ROL&gt; \
  --tokens-in &lt;N&gt; --tokens-out &lt;N&gt; --duration &lt;SEGUNDOS&gt; --source measured</pre>
          <div class="mt-1.5 text-amber-300/60 text-[10px]">Los valores los encontrás en el contador de tokens de tu IDE/CLI de IA (Antigravity, Gemini, etc.)</div>
        </div>
      </div>
      <!-- Live Pricing Status Bar -->
      <div class="flex items-center justify-between p-3.5 bg-slate-900 border border-slate-800 rounded-2xl text-xs flex-wrap gap-3 shadow-sm">
        <div class="flex items-center gap-2 flex-wrap">
          <span id="pricing-status-dot" class="inline-block w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
          <span id="pricing-status-text" class="font-semibold text-slate-200">Tarifas en vivo sincronizadas con OpenRouter API</span>
          <span id="pricing-models-count" class="px-2 py-0.5 rounded-md bg-slate-800 text-sky-400 font-mono text-[10px] border border-slate-700">Consultando...</span>
        </div>
        <div class="flex items-center gap-2">
          <button onclick="openCostMethodologyModal()" class="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-[11px] font-medium transition border border-slate-700 flex items-center gap-1.5">
            <span>ℹ️ Metodología y Precios</span>
          </button>
          <button onclick="refreshLivePricing(true)" id="refresh-pricing-btn" title="Refrescar tarifas en vivo" class="px-2.5 py-1 bg-slate-800 hover:bg-sky-600 hover:text-white text-slate-300 rounded-lg text-[11px] transition border border-slate-700">
            🔄
          </button>
        </div>
      </div>

      <!-- KPI Cards (5 Cards) -->
      <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm">
          <div class="text-xs text-slate-400 font-medium">Tokens Totales</div>
          <div id="kpi-tokens-total" class="text-2xl font-black text-sky-400 mt-1">0</div>
          <div class="text-[10px] text-slate-500 mt-1"><span id="kpi-tokens-in">0</span> in · <span id="kpi-tokens-out">0</span> out</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm relative group">
          <div class="flex items-center justify-between text-xs text-slate-400 font-medium">
            <span>Costo Est. API (USD)</span>
            <button onclick="openCostMethodologyModal()" title="Ver cómo se calcula" class="text-slate-500 hover:text-sky-400">ℹ️</button>
          </div>
          <div id="kpi-cost-total" class="text-2xl font-black text-emerald-400 mt-1">$0.00</div>
          <div class="text-[10px] text-slate-500 mt-1" id="kpi-cost-badge">s/ tarifas OpenRouter</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm">
          <div class="text-xs text-slate-400 font-medium">Promedio por Fase</div>
          <div id="kpi-tokens-avg" class="text-2xl font-black text-sky-300 mt-1">0</div>
          <div class="text-[10px] text-slate-500 mt-1" id="kpi-tokens-ratio">0% in · 0% out</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm">
          <div class="text-xs text-slate-400 font-medium">Sesiones de Agente</div>
          <div id="kpi-sessions" class="text-2xl font-black text-indigo-400 mt-1">0</div>
          <div class="text-[10px] text-slate-500 mt-1"><span id="kpi-retries">0</span> reintentos de gate</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm col-span-2 sm:col-span-1">
          <div class="text-xs text-slate-400 font-medium">Tiempo de Pipeline</div>
          <div id="kpi-time" class="text-2xl font-black text-amber-400 mt-1">0m</div>
          <div class="text-[10px] text-slate-500 mt-1">Duración acumulada de fases</div>
        </div>
      </div>

      <!-- Charts Grid (2x2 Layout) -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3 flex items-center justify-between">
            <span>Tokens por Rol</span>
            <span class="text-[10px] font-normal text-slate-500">In + Out</span>
          </h3>
          <div class="h-56 flex items-center justify-center">
            <canvas id="chart-roles"></canvas>
          </div>
        </div>

        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3 flex items-center justify-between">
            <span>Tokens por Fase</span>
            <span class="text-[10px] font-normal text-slate-500">Distribución</span>
          </h3>
          <div class="h-56 flex items-center justify-center">
            <canvas id="chart-phases"></canvas>
          </div>
        </div>

        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3 flex items-center justify-between">
            <span>Modelos de IA</span>
            <span class="text-[10px] font-normal text-slate-500">Tokens & Costo</span>
          </h3>
          <div class="h-56 flex items-center justify-center">
            <canvas id="chart-models"></canvas>
          </div>
        </div>

        <div class="bg-slate-900 border border-slate-800 p-5 rounded-2xl shadow-sm">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3 flex items-center justify-between">
            <span>Entornos de Ejecución</span>
            <span class="text-[10px] font-normal text-slate-500">Local / Staging / Prod</span>
          </h3>
          <div class="h-56 flex items-center justify-center">
            <canvas id="chart-environments"></canvas>
          </div>
        </div>
      </div>

      <!-- Executions History Table -->
      <div class="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-sm">
        <div class="p-5 border-b border-slate-800 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
          <div>
            <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider">Historial de Ejecuciones de Agentes</h3>
            <span id="table-count" class="text-xs text-slate-400 font-medium">0 ejecuciones</span>
          </div>

          <!-- Environment Filter Buttons -->
          <div class="flex items-center gap-1.5 flex-wrap text-xs">
            <span class="text-[11px] font-semibold text-slate-400 mr-1">Entorno:</span>
            <button onclick="setEnvFilter('ALL')" id="filter-env-ALL" class="filter-env-btn filter-btn active px-2.5 py-1 rounded-lg text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">Todos</button>
            <button onclick="setEnvFilter('local')" id="filter-env-local" class="filter-env-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">💻 Local</button>
            <button onclick="setEnvFilter('staging')" id="filter-env-staging" class="filter-env-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">🌐 Staging</button>
            <button onclick="setEnvFilter('production')" id="filter-env-production" class="filter-env-btn filter-btn px-2.5 py-1 rounded-lg text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700 transition">🚀 Producción</button>
          </div>
        </div>
        <div class="overflow-x-auto max-h-96 overflow-y-auto">
          <table class="w-full text-left text-xs">
            <thead class="bg-slate-950/90 text-slate-400 uppercase text-[10px] tracking-wider sticky top-0 border-b border-slate-800">
              <tr>
                <th class="py-3 px-4 font-semibold">Timestamp</th>
                <th class="py-3 px-4 font-semibold">Iniciativa</th>
                <th class="py-3 px-4 font-semibold">Rol</th>
                <th class="py-3 px-4 font-semibold">Fase</th>
                <th class="py-3 px-4 font-semibold">Modelo / IDE</th>
                <th class="py-3 px-4 font-semibold">Entorno / Rama</th>
                <th class="py-3 px-4 font-semibold">Tokens In</th>
                <th class="py-3 px-4 font-semibold">Tokens Out</th>
                <th class="py-3 px-4 font-semibold">Costo Est. ($)</th>
                <th class="py-3 px-4 font-semibold">Duración</th>
                <th class="py-3 px-4 font-semibold">Veredicto</th>
              </tr>
            </thead>
            <tbody id="executions-tbody" class="divide-y divide-slate-800/60 font-mono text-[11px]">
            </tbody>
          </table>
        </div>
      </div>
    </section>
  </main>

  <!-- Initiative Detail Modal Dialog (Mejorado & Enriquecido) -->
  <div id="initiative-modal" class="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 hidden flex items-center justify-center p-4">
    <div class="bg-slate-900 border border-slate-700/70 rounded-2xl max-w-4xl w-full max-h-[90vh] flex flex-col shadow-2xl overflow-hidden animate-modal">
      <!-- Modal Header -->
      <div class="p-5 sm:p-6 border-b border-slate-800/80 bg-slate-900/95 flex items-start justify-between gap-4">
        <div class="min-w-0 space-y-1.5">
          <div class="flex items-center gap-2 flex-wrap">
            <span id="modal-type-badge" class="px-2.5 py-0.5 rounded-full text-[10px] font-bold">FEAT</span>
            <span id="modal-status-badge" class="px-2.5 py-0.5 rounded-full text-[10px] font-medium bg-slate-800 text-slate-300">ACTIVA</span>
            <span id="modal-qa-badge" class="px-2.5 py-0.5 rounded-full text-[10px] font-bold">QA: PENDING</span>
          </div>
          <div class="flex items-center gap-2">
            <h3 id="modal-title" class="text-base sm:text-lg font-bold text-sky-400 font-mono truncate">FEAT-001</h3>
            <button onclick="copyCurrentInitiativeId()" title="Copiar ID" class="text-slate-400 hover:text-sky-300 text-xs px-1.5 py-0.5 rounded bg-slate-800 hover:bg-slate-700 transition">📋</button>
          </div>
          <p id="modal-desc" class="text-xs text-slate-300 leading-relaxed"></p>
        </div>
        
        <div class="flex items-center gap-1.5 flex-shrink-0">
          <button id="modal-prev-btn" onclick="navigateModal(-1)" title="Iniciativa anterior (Flecha Izquierda)" class="px-2.5 py-1 text-xs font-semibold bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg border border-slate-700 transition">← Ant</button>
          <button id="modal-next-btn" onclick="navigateModal(1)" title="Iniciativa siguiente (Flecha Derecha)" class="px-2.5 py-1 text-xs font-semibold bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg border border-slate-700 transition">Sig →</button>
          <button onclick="closeInitiativeModal()" class="text-slate-400 hover:text-slate-200 text-lg font-bold p-1 rounded-lg hover:bg-slate-800 transition ml-2">✕</button>
        </div>
      </div>

      <!-- Modal Sub-Tabs -->
      <div class="flex border-b border-slate-800 bg-slate-950/60 px-5 sm:px-6 pt-2 gap-2 text-xs">
        <button onclick="switchModalTab('artifacts')" id="modal-tab-btn-artifacts" class="modal-tab-btn px-3 py-2 font-semibold border-b-2 border-sky-500 text-sky-400 transition">📄 Artefactos SDD</button>
        <button onclick="switchModalTab('telemetry')" id="modal-tab-btn-telemetry" class="modal-tab-btn px-3 py-2 font-semibold border-b-2 border-transparent text-slate-400 hover:text-slate-200 transition">⚡ Telemetría & Fases</button>
        <button onclick="switchModalTab('cli')" id="modal-tab-btn-cli" class="modal-tab-btn px-3 py-2 font-semibold border-b-2 border-transparent text-slate-400 hover:text-slate-200 transition">💻 Comandos CLI</button>
      </div>

      <!-- Modal Body -->
      <div class="p-5 sm:p-6 overflow-y-auto space-y-5 text-xs flex-1">
        <!-- Tab 1: Artifacts -->
        <div id="modal-tab-artifacts" class="space-y-4">
          <div>
            <h4 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-2.5">Matriz de Documentación Metodológica (SDD)</h4>
            <div id="modal-artifacts-grid" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2.5"></div>
          </div>

          <div class="p-4 bg-slate-950/70 border border-slate-800/80 rounded-xl space-y-2">
            <span class="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block">Directorio de la Iniciativa</span>
            <div class="flex items-center justify-between gap-2 bg-slate-900 p-2 rounded-lg border border-slate-800 font-mono text-[11px] text-sky-300">
              <span id="modal-folder-path-display" class="truncate">.ai/features/...</span>
              <button onclick="copyModalFolderPath()" class="px-2.5 py-1 bg-slate-800 hover:bg-sky-600 hover:text-white text-slate-300 rounded text-[10px] font-sans font-medium transition border border-slate-700 flex-shrink-0">Copiar Ruta</button>
            </div>
          </div>
        </div>

        <!-- Tab 2: Telemetry -->
        <div id="modal-tab-telemetry" class="hidden space-y-4">
          <div id="modal-telemetry-empty" class="text-slate-500 text-xs italic py-6 text-center bg-slate-950/40 rounded-xl border border-slate-800/60">
            No hay ejecuciones registradas en <code>.ai/metrics/executions.yaml</code> para esta iniciativa.
          </div>
          <div id="modal-telemetry-content" class="hidden space-y-4">
            <div class="grid grid-cols-3 gap-3 text-center bg-slate-950 p-4 rounded-xl border border-slate-800/80 shadow-inner">
              <div>
                <div class="text-[10px] text-slate-400 font-medium uppercase">Tokens Totales</div>
                <div id="modal-tokens-total" class="font-black text-sky-400 text-base mt-0.5">0</div>
              </div>
              <div>
                <div class="text-[10px] text-slate-400 font-medium uppercase">Fases Registradas</div>
                <div id="modal-phases-count" class="font-black text-indigo-400 text-base mt-0.5">0</div>
              </div>
              <div>
                <div class="text-[10px] text-slate-400 font-medium uppercase">Duración Total</div>
                <div id="modal-duration-total" class="font-black text-emerald-400 text-base mt-0.5">0s</div>
              </div>
            </div>
            <div class="border border-slate-800/80 rounded-xl overflow-hidden shadow-sm">
              <table class="w-full text-left text-[11px]">
                <thead class="bg-slate-950/90 text-slate-400 uppercase text-[9px] border-b border-slate-800">
                  <tr>
                    <th class="p-2.5">Rol / Fase</th>
                    <th class="p-2.5">Tokens In / Out</th>
                    <th class="p-2.5">Duración</th>
                    <th class="p-2.5">Veredicto Gate</th>
                  </tr>
                </thead>
                <tbody id="modal-executions-tbody" class="divide-y divide-slate-800/60 font-mono"></tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Tab 3: CLI Commands -->
        <div id="modal-tab-cli" class="hidden space-y-4">
          <div class="space-y-3">
            <div>
              <span class="text-slate-400 text-xs block mb-1 font-medium">Abrir directorio en VSCode / IDE:</span>
              <div class="flex items-center justify-between gap-2 bg-slate-950 p-2.5 rounded-lg border border-slate-800 font-mono text-xs text-emerald-400">
                <span id="modal-cmd-code" class="truncate">code .ai/features/...</span>
                <button onclick="copyTextFromElement('modal-cmd-code', 'Comando copiado')" class="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded text-[10px] font-sans font-medium transition border border-slate-700 flex-shrink-0">Copiar</button>
              </div>
            </div>

            <div>
              <span class="text-slate-400 text-xs block mb-1 font-medium">Cerrar fase y registrar métricas:</span>
              <div class="flex items-center justify-between gap-2 bg-slate-950 p-2.5 rounded-lg border border-slate-800 font-mono text-xs text-sky-400">
                <span id="modal-cmd-finish" class="truncate">bash .ai/agents/scripts/finish-phase.sh ...</span>
                <button onclick="copyTextFromElement('modal-cmd-finish', 'Comando copiado')" class="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded text-[10px] font-sans font-medium transition border border-slate-700 flex-shrink-0">Copiar</button>
              </div>
            </div>

            <div>
              <span class="text-slate-400 text-xs block mb-1 font-medium">Sincronizar y auto-reparar documentación:</span>
              <div class="flex items-center justify-between gap-2 bg-slate-950 p-2.5 rounded-lg border border-slate-800 font-mono text-xs text-indigo-400">
                <span id="modal-cmd-sync" class="truncate">bash .ai/agents/scripts/sync-initiatives.sh --fix</span>
                <button onclick="copyTextFromElement('modal-cmd-sync', 'Comando copiado')" class="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded text-[10px] font-sans font-medium transition border border-slate-700 flex-shrink-0">Copiar</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Modal Footer -->
      <div class="p-4 sm:p-5 border-t border-slate-800/80 bg-slate-950/80 flex items-center justify-between">
        <span class="text-[11px] text-slate-500 font-mono truncate mr-2" id="modal-folder-path">.ai/features/FEAT-001</span>
        <button onclick="closeInitiativeModal()" class="px-4 py-1.5 bg-slate-800 hover:bg-slate-700 text-xs text-slate-200 font-semibold rounded-xl border border-slate-700 transition">Cerrar</button>
      </div>
    </div>
  </div>

  <!-- About Abbia OS Modal Dialog -->
  <div id="about-modal" class="fixed inset-0 bg-slate-950/85 backdrop-blur-md z-50 hidden flex items-center justify-center p-4">
    <div class="bg-slate-900 border border-slate-700/80 rounded-2xl max-w-3xl w-full max-h-[90vh] flex flex-col shadow-2xl overflow-hidden animate-modal">
      <!-- Modal Header -->
      <div class="p-5 sm:p-6 border-b border-slate-800/80 bg-slate-900/95 flex items-start justify-between gap-4">
        <div class="flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-slate-950/80 border border-sky-500/30 flex items-center justify-center shadow-inner flex-shrink-0 p-1.5">
            <svg class="w-full h-full" viewBox="0 0 240 240" fill="none" xmlns="http://www.w3.org/2000/svg">
              <line x1="120" y1="36" x2="35" y2="195" stroke="#38bdf8" stroke-width="6" stroke-linecap="round"/>
              <line x1="120" y1="54" x2="48" y2="195" stroke="#0284c7" stroke-width="4.5" stroke-linecap="round" opacity="0.85"/>
              <line x1="120" y1="36" x2="205" y2="195" stroke="#38bdf8" stroke-width="6" stroke-linecap="round"/>
              <line x1="120" y1="54" x2="192" y2="195" stroke="#0284c7" stroke-width="4.5" stroke-linecap="round" opacity="0.85"/>
              <polygon points="120,22 112,35 128,35" fill="#38bdf8"/>
              <line x1="78" y1="120" x2="108" y2="120" stroke="#34d399" stroke-width="5" stroke-linecap="round"/>
              <line x1="78" y1="128" x2="108" y2="128" stroke="#34d399" stroke-width="5" stroke-linecap="round"/>
              <line x1="132" y1="120" x2="162" y2="120" stroke="#34d399" stroke-width="5" stroke-linecap="round"/>
              <line x1="132" y1="128" x2="162" y2="128" stroke="#34d399" stroke-width="5" stroke-linecap="round"/>
              <circle cx="78" cy="124" r="10" fill="#34d399" stroke="#065f46" stroke-width="3"/>
              <circle cx="162" cy="124" r="10" fill="#34d399" stroke="#065f46" stroke-width="3"/>
              <polygon points="120,111 133,124 120,137 107,124" fill="#a855f7" stroke="#e9d5ff" stroke-width="2"/>
              <line x1="35" y1="191" x2="205" y2="191" stroke="#34d399" stroke-width="6" stroke-linecap="round"/>
              <line x1="35" y1="199" x2="205" y2="199" stroke="#34d399" stroke-width="6" stroke-linecap="round"/>
              <circle cx="35" cy="195" r="12" fill="#34d399" stroke="#065f46" stroke-width="3"/>
              <circle cx="205" cy="195" r="12" fill="#34d399" stroke="#065f46" stroke-width="3"/>
            </svg>
          </div>
          <div>
            <div class="flex items-center gap-2 flex-wrap">
              <h3 class="text-base sm:text-lg font-black bg-gradient-to-r from-sky-400 via-indigo-300 to-teal-300 bg-clip-text text-transparent">Abbia OS</h3>
              <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-sky-500/20 text-sky-300 border border-sky-500/30">v4.0.0</span>
            </div>
            <p class="text-xs text-slate-400 mt-0.5">Layered Context, Structured Memory, Autonomous Delivery (SDD)</p>
          </div>
        </div>
        <button onclick="closeAboutModal()" class="text-slate-400 hover:text-slate-200 text-lg font-bold p-1 rounded-lg hover:bg-slate-800 transition">✕</button>
      </div>

      <!-- Modal Body -->
      <div class="p-5 sm:p-6 overflow-y-auto space-y-6 text-xs text-slate-300 flex-1 leading-relaxed">
        <!-- Overview Banner -->
        <div class="bg-slate-950/70 border border-slate-800/80 p-4 rounded-xl space-y-2">
          <h4 class="text-xs font-bold text-sky-400 uppercase tracking-wider flex items-center gap-2">
            <span>🎯</span> ¿Qué es Abbia OS?
          </h4>
          <p class="text-slate-300 leading-relaxed">
            <strong>Abbia OS</strong> es un sistema operativo de ingeniería y framework de orquestación para desarrollo de software asistido por IA. Implementa la metodología <strong>Specification-Driven Development (SDD)</strong>: primero la especificación funcional, el diseño visual y la arquitectura técnica aprobada, luego la implementación guiada por agentes especializados con control de calidad continuo y memoria técnica persistente.
          </p>
        </div>

        <!-- 3 Pillars Grid -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
          <div class="bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/80 space-y-1.5">
            <div class="font-bold text-sky-400 flex items-center gap-1.5 text-xs">
              <span>👥</span> 8 Roles Especializados
            </div>
            <p class="text-[11px] text-slate-400">Analyst, UI Designer, Architect, Tech Lead, Senior Developer, QA Engineer, DevOps y Skill Manager colaborando en fases claras con Context Contracts.</p>
          </div>

          <div class="bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/80 space-y-1.5">
            <div class="font-bold text-indigo-400 flex items-center gap-1.5 text-xs">
              <span>🔄</span> Workflows con DAG
            </div>
            <p class="text-[11px] text-slate-400">Flujos formales para New Feature, Bug Fix, Refactor, Release y Architecture Change con gates de calidad obligatorios.</p>
          </div>

          <div class="bg-slate-950/60 p-3.5 rounded-xl border border-slate-800/80 space-y-1.5">
            <div class="font-bold text-emerald-400 flex items-center gap-1.5 text-xs">
              <span>🧠</span> 3-Tier Persistent Memory
            </div>
            <p class="text-[11px] text-slate-400">Context Snapshot (Tier 2), Workflow Log (Tier 1), Knowledge Graph (Tier 3) y Patterns Learned (procedimental).</p>
          </div>
        </div>

        <!-- Automation Scripts & CLI Reference -->
        <div class="space-y-2.5">
          <h4 class="text-xs font-bold text-slate-200 uppercase tracking-wider flex items-center gap-2">
            <span>⚙️</span> Comandos CLI de Abbia OS
          </h4>
          <div class="space-y-2 font-mono text-[11px]">
            <div class="bg-slate-950 p-2.5 rounded-xl border border-slate-800/80 flex items-center justify-between gap-2">
              <span class="text-sky-300 truncate">./abbia new &lt;TIPO&gt; &lt;ID&gt; &lt;slug&gt;</span>
              <span class="text-slate-500 font-sans text-[10px] flex-shrink-0">Crear iniciativa</span>
            </div>
            <div class="bg-slate-950 p-2.5 rounded-xl border border-slate-800/80 flex items-center justify-between gap-2">
              <span class="text-indigo-300 truncate">./abbia finish &lt;INICIATIVA&gt; &lt;FASE&gt; [ROL]</span>
              <span class="text-slate-500 font-sans text-[10px] flex-shrink-0">Registrar fase & telemetría</span>
            </div>
            <div class="bg-slate-950 p-2.5 rounded-xl border border-slate-800/80 flex items-center justify-between gap-2">
              <span class="text-emerald-300 truncate">./abbia sync --fix</span>
              <span class="text-slate-500 font-sans text-[10px] flex-shrink-0">Auto-reparar & sincronizar</span>
            </div>
            <div class="bg-slate-950 p-2.5 rounded-xl border border-slate-800/80 flex items-center justify-between gap-2">
              <span class="text-amber-300 truncate">./abbia validate</span>
              <span class="text-slate-500 font-sans text-[10px] flex-shrink-0">Validar estructura</span>
            </div>
            <div class="bg-slate-950 p-2.5 rounded-xl border border-slate-800/80 flex items-center justify-between gap-2">
              <span class="text-teal-300 truncate">./abbia dashboard</span>
              <span class="text-slate-500 font-sans text-[10px] flex-shrink-0">Abrir visualizador</span>
            </div>
          </div>
        </div>

        <!-- Links & Submodule Info -->
        <div class="border-t border-slate-800/80 pt-4 flex flex-col sm:flex-row items-center justify-between gap-3 text-[11px]">
          <div class="text-slate-400">
            Núcleo integrado en: <code class="text-sky-400 font-mono">.abbia/core/</code>
          </div>
          <div class="flex items-center gap-3">
            <a href="https://github.com/ezequielmendoza-dev/abbia-os" target="_blank" class="text-sky-400 hover:text-sky-300 font-semibold flex items-center gap-1 transition">
              <span>🌐</span> Repositorio GitHub ↗
            </a>
          </div>
        </div>
      </div>

      <!-- Modal Footer -->
      <div class="p-4 sm:p-5 border-t border-slate-800/80 bg-slate-950/80 flex items-center justify-between">
        <span class="text-[11px] text-slate-500">Diseñado para Pair Programming Humano + IA</span>
        <button onclick="closeAboutModal()" class="px-4 py-1.5 bg-slate-800 hover:bg-slate-700 text-xs text-slate-200 font-semibold rounded-xl border border-slate-700 transition">Cerrar</button>
      </div>
    </div>
  </div>

  <!-- Cost Methodology & Pricing Transparency Modal -->
  <div id="cost-methodology-modal" class="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 hidden flex items-center justify-center p-4">
    <div class="bg-slate-900 border border-slate-700/70 rounded-2xl max-w-3xl w-full max-h-[90vh] flex flex-col shadow-2xl overflow-hidden animate-modal">
      <!-- Modal Header -->
      <div class="p-5 sm:p-6 border-b border-slate-800/80 bg-slate-900/95 flex items-start justify-between gap-4">
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">TRANSPARENCIA DE COSTOS</span>
            <span id="modal-pricing-live-badge" class="px-2.5 py-0.5 rounded-full text-[10px] font-mono bg-slate-800 text-sky-300">OpenRouter API</span>
          </div>
          <h3 class="text-base sm:text-lg font-bold text-slate-100 flex items-center gap-2">
            <span>💵</span> Metodología de Estimación de Costos de IA
          </h3>
          <p class="text-xs text-slate-400">Cómo se calculan los importes en USD y de dónde se obtienen las tarifas oficiales.</p>
        </div>
        <button onclick="closeCostMethodologyModal()" class="text-slate-400 hover:text-slate-200 text-lg font-bold p-1 rounded-lg hover:bg-slate-800 transition">✕</button>
      </div>

      <!-- Modal Body -->
      <div class="p-5 sm:p-6 overflow-y-auto space-y-5 text-xs text-slate-300 leading-relaxed">
        <!-- Live API Source Notice -->
        <div class="p-4 bg-emerald-950/40 border border-emerald-800/60 rounded-xl space-y-2">
          <div class="font-bold text-emerald-300 flex items-center gap-1.5">
            <span>🌐</span> Fuente en Tiempo Real (Sin Hardcoding)
          </div>
          <p class="text-emerald-200/90 text-xs leading-relaxed">
            Las tarifas por millón de tokens se consultan <strong>directamente en vivo desde la API pública de OpenRouter</strong> (<code class="bg-slate-900 px-1 py-0.5 rounded text-emerald-400">openrouter.ai/api/v1/models</code>), que mantiene al día los precios de más de 400 modelos de Google (Gemini), Anthropic (Claude), OpenAI (GPT), DeepSeek, Meta (Llama), Mistral y Qwen.
          </p>
          <div class="text-[11px] text-emerald-300/70 pt-1 flex items-center justify-between">
            <span id="modal-pricing-sync-time">Última sincronización: consultando...</span>
            <a href="https://openrouter.ai/models" target="_blank" class="text-sky-400 hover:underline">Ver catálogo OpenRouter ↗</a>
          </div>
        </div>

        <!-- Formula -->
        <div class="p-4 bg-slate-950/70 border border-slate-800/80 rounded-xl space-y-2">
          <div class="font-bold text-sky-400 flex items-center gap-1.5">
            <span>📐</span> Fórmula Matemática de Cálculo
          </div>
          <div class="bg-slate-900 p-3 rounded-lg font-mono text-[11px] text-slate-200 border border-slate-800 text-center overflow-x-auto">
            Costo USD = (Tokens In × Tarifa Prompt / 1.000.000) + (Tokens Out × Tarifa Completion / 1.000.000)
          </div>
          <p class="text-slate-400 text-[11px]">
            La fórmula separa estrictamente los tokens de entrada (prompts de contexto y código) de los tokens de salida (respuestas y diffs generados), multiplicando por la tarifa oficial correspondiente de cada modelo.
          </p>
        </div>

        <!-- Subscription vs API Clarification -->
        <div class="p-4 bg-amber-500/10 border border-amber-500/30 rounded-xl space-y-2">
          <div class="font-bold text-amber-300 flex items-center gap-1.5">
            <span>⚠️</span> Suscripciones Planas vs. Facturación Pay-as-you-go
          </div>
          <p class="text-amber-200/90 text-xs leading-relaxed">
            Si utilizas herramientas con <strong>tarifa plana mensual</strong> (como Antigravity, Cursor Pro, Claude Pro o ChatGPT Plus), este costo <strong>no representa un cobro bancario adicional</strong>, sino el <em>valor económico de mercado equivalente</em> del cómputo realizado por la IA para esa iniciativa.
          </p>
        </div>

        <!-- Model Pricing Lookup -->
        <div class="space-y-3">
          <div class="flex items-center justify-between gap-2 flex-wrap">
            <h4 class="text-xs font-bold text-slate-200 uppercase tracking-wider">Tarifas Activas Detectadas</h4>
            <input type="text" id="pricing-search-input" oninput="filterPricingTable()" placeholder="Buscar modelo (ej: gemini, claude, deepseek)..." class="bg-slate-950 border border-slate-800 rounded-lg px-2.5 py-1 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-sky-500 w-64">
          </div>
          <div class="border border-slate-800 rounded-xl overflow-hidden max-h-56 overflow-y-auto">
            <table class="w-full text-left text-xs">
              <thead class="bg-slate-950/90 text-slate-400 uppercase text-[10px] sticky top-0 border-b border-slate-800">
                <tr>
                  <th class="py-2.5 px-3">Modelo</th>
                  <th class="py-2.5 px-3">Prompt (1M tokens)</th>
                  <th class="py-2.5 px-3">Completion (1M tokens)</th>
                  <th class="py-2.5 px-3">Proveedor</th>
                </tr>
              </thead>
              <tbody id="pricing-tbody" class="divide-y divide-slate-800/60 font-mono text-[11px]">
                <tr><td colspan="4" class="py-4 text-center text-slate-500">Cargando tarifas en vivo...</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Modal Footer -->
      <div class="p-4 sm:p-5 border-t border-slate-800/80 bg-slate-950/80 flex items-center justify-between">
        <span class="text-[11px] text-slate-500">Precios actualizados automáticamente vía OpenRouter API</span>
        <button onclick="closeCostMethodologyModal()" class="px-4 py-1.5 bg-slate-800 hover:bg-slate-700 text-xs text-slate-200 font-semibold rounded-xl border border-slate-700 transition">Cerrar</button>
      </div>
    </div>
  </div>

  <!-- Toast Notification -->
  <div id="toast" class="fixed bottom-5 right-5 bg-sky-500 text-white font-semibold text-xs px-4 py-2.5 rounded-xl shadow-2xl transition-all duration-300 transform translate-y-16 opacity-0 pointer-events-none z-50 flex items-center gap-2">
    <span>✅</span>
    <span id="toast-message">Copiado al portapapeles</span>
  </div>

  <script>
    // --- Data Parsing ---
    let projectMeta = {
      name: "Proyecto",
      type: "Software",
      status: "Activo",
      repo: "-",
      root: "-",
      startDate: "-",
      updatedDate: "-",
      basename: "project"
    };
    let kgData = { nodes: [], edges: [] };
    let metricsData = { executions: [] };
    let allInitiatives = [];
    let currentFilteredInitiatives = [];
    let currentModalIndex = -1;

    try {
      projectMeta = JSON.parse(document.getElementById('raw-project').textContent.trim() || '{}');
    } catch (e) { console.error('Error parseando Project Meta JSON:', e); }

    function safeLoadYaml(yamlStr, defaultVal) {
      if (!yamlStr || !yamlStr.trim()) return defaultVal;
      try {
        return jsyaml.load(yamlStr) || defaultVal;
      } catch (err) {
        console.warn('YAML Parse Warning, reintentando con sanitización de comillas:', err);
        try {
          // Auto-repair unescaped inner quotes on lines like: title: "foo "bar" baz"
          const sanitized = yamlStr.split('\n').map(line => {
            const match = line.match(/^(\s*[a-zA-Z0-9_-]+:\s*)"(.*)"\s*$/);
            if (match) {
              const prefix = match[1];
              const inner = match[2].replace(/"/g, "'");
              return `${prefix}"${inner}"`;
            }
            return line;
          }).join('\n');
          return jsyaml.load(sanitized) || defaultVal;
        } catch (err2) {
          console.error('Error parseando YAML:', err2);
          return defaultVal;
        }
      }
    }

    try {
      const kgRaw = document.getElementById('raw-kg').textContent;
      kgData = safeLoadYaml(kgRaw, { nodes: [], edges: [] });
    } catch (e) { console.error('Error parseando KG YAML:', e); }

    try {
      const metricsRaw = document.getElementById('raw-metrics').textContent;
      metricsData = safeLoadYaml(metricsRaw, { executions: [] });
    } catch (e) { console.error('Error parseando Metrics YAML:', e); }

    try {
      allInitiatives = JSON.parse(document.getElementById('raw-initiatives').textContent.trim() || '[]');
    } catch (e) { console.error('Error parseando Iniciativas JSON:', e); }

    const contextRaw = document.getElementById('raw-context').textContent;
    const logRaw = document.getElementById('raw-log').textContent;
    const catalogRaw = document.getElementById('raw-catalog').textContent;
    const patternsRaw = document.getElementById('raw-patterns').textContent;
    const snapshotRaw = document.getElementById('raw-snapshot').textContent;
    const rulesRaw = document.getElementById('raw-rules').textContent;
    const glossaryRaw = document.getElementById('raw-glossary').textContent;

    // Timestamp formatting helper (handles Date objects from js-yaml as well as string timestamps)
    function formatTimestamp(ts) {
      if (!ts) return '-';
      if (ts instanceof Date) {
        return ts.toISOString().replace('T', ' ').replace('Z', '').substring(0, 19);
      }
      return String(ts).replace('T', ' ').replace('Z', '').substring(0, 19);
    }

    // Toast feedback helper
    function showToast(msg) {
      const toast = document.getElementById('toast');
      const toastMsg = document.getElementById('toast-message');
      if (!toast || !toastMsg) return;
      toastMsg.textContent = msg;
      toast.classList.remove('translate-y-16', 'opacity-0');
      toast.classList.add('translate-y-0', 'opacity-100');
      setTimeout(() => {
        toast.classList.add('translate-y-16', 'opacity-0');
        toast.classList.remove('translate-y-0', 'opacity-100');
      }, 2400);
    }

    function copyToClipboard(text, successMsg = 'Copiado al portapapeles') {
      if (!text) return;
      navigator.clipboard.writeText(text).then(() => {
        showToast(successMsg);
      }).catch(err => {
        console.error('Error copiando:', err);
      });
    }

    function copyTextFromElement(elemId, successMsg) {
      const el = document.getElementById(elemId);
      if (el) copyToClipboard(el.textContent.trim(), successMsg);
    }

    // --- Project Data Rendering ---
    function initProject() {
      // Clean repo string (strip surrounding quotes or backticks)
      let cleanRepo = (projectMeta.repo || '').replace(/^[`'"]+|[`'"]+$/g, '').trim();
      if (!cleanRepo || cleanRepo === '-') cleanRepo = projectMeta.basename || 'controlfit-webapp';

      // 1. Navbar
      if (document.getElementById('nav-project-name')) document.getElementById('nav-project-name').textContent = projectMeta.name || projectMeta.basename || 'ai-agents OS';
      if (document.getElementById('nav-project-status')) document.getElementById('nav-project-status').textContent = projectMeta.status || 'Activo';
      if (document.getElementById('nav-project-type')) document.getElementById('nav-project-type').textContent = projectMeta.type || 'Software';
      if (document.getElementById('nav-project-repo')) document.getElementById('nav-project-repo').textContent = cleanRepo;
      if (document.getElementById('nav-project-path')) {
        document.getElementById('nav-project-path').textContent = projectMeta.root || '';
        document.getElementById('nav-project-path').title = "Ruta: " + (projectMeta.root || '');
      }

      // 2. Hero Card
      if (document.getElementById('hero-project-title')) document.getElementById('hero-project-title').textContent = projectMeta.name || projectMeta.basename || 'ControlFit';
      if (document.getElementById('hero-project-type-badge')) document.getElementById('hero-project-type-badge').textContent = projectMeta.type || 'Software';
      if (document.getElementById('hero-project-status-badge')) document.getElementById('hero-project-status-badge').textContent = projectMeta.status || 'En producción';
      if (document.getElementById('hero-project-updated')) document.getElementById('hero-project-updated').textContent = projectMeta.updatedDate || '2026-09-12';

      // Repo Link
      const repoLinkEl = document.getElementById('hero-project-repo-link');
      const repoTextEl = document.getElementById('hero-project-repo-text');
      const detailRepoEl = document.getElementById('meta-detail-repo');
      const detailPathEl = document.getElementById('meta-detail-path');

      if (cleanRepo && cleanRepo !== '-') {
        if (repoLinkEl) {
          repoLinkEl.href = cleanRepo.startsWith('http') ? cleanRepo : (cleanRepo.includes('github.com') ? 'https://' + cleanRepo : 'https://github.com/' + cleanRepo);
        }
        if (repoTextEl) repoTextEl.textContent = cleanRepo;
        if (detailRepoEl) detailRepoEl.textContent = cleanRepo;
      } else {
        if (repoLinkEl) repoLinkEl.classList.add('hidden');
        if (detailRepoEl) detailRepoEl.textContent = projectMeta.basename || 'Local';
      }

      if (detailPathEl) detailPathEl.textContent = projectMeta.root || '-';

      // 3. Metadata Grid
      if (document.getElementById('meta-project-type')) document.getElementById('meta-project-type').textContent = projectMeta.type || '-';
      if (document.getElementById('meta-project-status')) document.getElementById('meta-project-status').textContent = projectMeta.status || '-';
      if (document.getElementById('meta-project-path')) document.getElementById('meta-project-path').textContent = projectMeta.root || '-';

      // 4. Parse Sections from contextRaw
      let descText = "Sin descripción definida.";
      const descMatch = contextRaw.match(/## 1\.\s*Descripción del Proyecto([\s\S]*?)(?=## 2\.|$)/i);
      if (descMatch && descMatch[1]) {
        descText = descMatch[1].trim();
        const cleanHeroDesc = descText.replace(/^>\s*/gm, '').replace(/\n/g, ' ').substring(0, 280);
        if (document.getElementById('hero-project-desc')) {
          document.getElementById('hero-project-desc').textContent = cleanHeroDesc + (cleanHeroDesc.length >= 280 ? '...' : '');
        }
      }

      // Extract Goals (§2)
      let goalsHtml = "<p class='text-slate-500 italic'>Sin objetivos documentados en context.md.</p>";
      const goalsMatch = contextRaw.match(/## 2\.\s*Objetivos de Negocio([\s\S]*?)(?=## 3\.|$)/i);
      if (goalsMatch && goalsMatch[1]) {
        goalsHtml = marked.parse(goalsMatch[1].trim());
      }
      if (document.getElementById('project-goals-content')) {
        document.getElementById('project-goals-content').innerHTML = goalsHtml;
      }

      // Extract Actors (§3)
      let actorsHtml = "<p class='text-slate-500 italic'>Sin actores documentados en context.md.</p>";
      const actorsMatch = contextRaw.match(/## 3\.\s*Usuarios \/ Actores([\s\S]*?)(?=## 4\.|$)/i);
      if (actorsMatch && actorsMatch[1]) {
        actorsHtml = marked.parse(actorsMatch[1].trim());
      }
      if (document.getElementById('project-actors-content')) {
        document.getElementById('project-actors-content').innerHTML = actorsHtml;
      }

      // Extract Tech Stack (§4)
      let stackHtml = "<p class='text-slate-500 italic'>Sin stack tecnológico documentado en context.md.</p>";
      const stackMatch = contextRaw.match(/## 4\.\s*Stack Tecnológico([\s\S]*?)(?=## 5\.|$)/i);
      if (stackMatch && stackMatch[1]) {
        stackHtml = marked.parse(stackMatch[1].trim());
      }
      if (document.getElementById('project-stack-content')) {
        document.getElementById('project-stack-content').innerHTML = stackHtml;
      }

      // Full Context Markdown
      if (document.getElementById('project-context-full-content')) {
        document.getElementById('project-context-full-content').innerHTML = marked.parse(contextRaw);
      }
    }

    // --- Tab Navigation ---
    function switchTab(tabId) {
      document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
      document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('bg-sky-500', 'text-white', 'shadow-lg', 'shadow-sky-500/20');
        btn.classList.add('text-slate-400');
      });
      
      document.getElementById('tab-' + tabId).classList.add('active');
      const activeBtn = document.getElementById('tab-btn-' + tabId);
      activeBtn.classList.remove('text-slate-400');
      activeBtn.classList.add('bg-sky-500', 'text-white', 'shadow-lg', 'shadow-sky-500/20');

      if (tabId === 'graph') {
        setTimeout(() => {
          if (!network) {
            initGraph();
          } else {
            network.setSize('100%', '640px');
            network.redraw();
            network.fit({ animation: { duration: 300 } });
          }
        }, 50);
      }
    }

    // --- Sub-Tab Navigation Helpers ---
    function switchProjectSubTab(subId) {
      document.querySelectorAll('.project-subpanel').forEach(el => el.classList.add('hidden'));
      document.querySelectorAll('.project-subtab-btn').forEach(btn => {
        btn.classList.remove('bg-sky-500', 'text-white', 'shadow-sm');
        btn.classList.add('text-slate-400');
      });
      const target = document.getElementById('project-subpanel-' + subId);
      if (target) target.classList.remove('hidden');
      const btn = document.getElementById('btn-project-sub-' + subId);
      if (btn) {
        btn.classList.remove('text-slate-400');
        btn.classList.add('bg-sky-500', 'text-white', 'shadow-sm');
      }
    }

    function switchRulesSubTab(subId) {
      document.querySelectorAll('.rules-subpanel').forEach(el => el.classList.add('hidden'));
      document.querySelectorAll('.rules-subtab-btn').forEach(btn => {
        btn.classList.remove('bg-sky-500', 'text-white', 'shadow-sm');
        btn.classList.add('text-slate-400');
      });
      const target = document.getElementById('rules-subpanel-' + subId);
      if (target) target.classList.remove('hidden');
      const btn = document.getElementById('btn-rules-sub-' + subId);
      if (btn) {
        btn.classList.remove('text-slate-400');
        btn.classList.add('bg-sky-500', 'text-white', 'shadow-sm');
      }
      const badge = document.getElementById('rules-file-badge');
      if (badge) badge.textContent = subId === 'rules' ? '.ai/business-rules.md' : '.ai/glossary.md';
    }

    function switchMemorySubTab(subId) {
      document.querySelectorAll('.memory-subpanel').forEach(el => el.classList.add('hidden'));
      document.querySelectorAll('.memory-subtab-btn').forEach(btn => {
        btn.classList.remove('bg-sky-500', 'text-white', 'shadow-sm');
        btn.classList.add('text-slate-400');
      });
      const target = document.getElementById('memory-subpanel-' + subId);
      if (target) target.classList.remove('hidden');
      const btn = document.getElementById('btn-memory-sub-' + subId);
      if (btn) {
        btn.classList.remove('text-slate-400');
        btn.classList.add('bg-sky-500', 'text-white', 'shadow-sm');
      }
    }

    // --- Graph & ADR Architecture Visualization ---
    let network = null;
    let visNodes = null;
    let visEdges = null;
    let currentGraphTypeFilter = 'ALL';
    let currentGraphSearchQuery = '';

    function initGraph() {
      const container = document.getElementById('network-canvas');
      if (!container) return;

      const nodes = (kgData.nodes || []);
      const countEl = document.getElementById('graph-node-count');
      if (countEl) countEl.textContent = `${nodes.length} decisiones`;

      let featCount = 0;
      let bugCount = 0;
      nodes.forEach(n => {
        const id = n.id || '';
        const title = n.title || '';
        if (id.includes('FEAT') || title.includes('FEAT') || title.includes('Feature') || title.includes('Especificación')) {
          if (title.includes('Bug') || title.includes('BUG') || id.includes('BUG')) {
            bugCount++;
          } else {
            featCount++;
          }
        } else if (id.includes('BUG') || title.includes('BUG') || title.includes('Bug')) {
          bugCount++;
        } else {
          featCount++;
        }
      });

      if (document.getElementById('count-graph-all')) document.getElementById('count-graph-all').textContent = nodes.length;
      if (document.getElementById('count-graph-feat')) document.getElementById('count-graph-feat').textContent = featCount;
      if (document.getElementById('count-graph-bug')) document.getElementById('count-graph-bug').textContent = bugCount;

      renderAdrMatrix();

      if (nodes.length === 0) {
        container.innerHTML = `
          <div class="flex flex-col items-center justify-center h-full text-slate-500 py-24">
            <span class="text-4xl">🕸️</span>
            <p class="mt-3 text-sm font-medium">No se encontraron decisiones registradas en knowledge-graph.yaml</p>
          </div>
        `;
        return;
      }

      const nodesArray = [];
      const edgesArray = [];
      const cols = Math.max(4, Math.ceil(Math.sqrt(nodes.length * 1.5)));

      nodes.forEach((node, idx) => {
        let borderColor = '#10b981'; // ACTIVE = emerald
        if (node.status === 'PENDING') borderColor = '#f59e0b';
        if (node.status === 'SUPERSEDED' || node.status === 'DEPRECATED') borderColor = '#64748b';

        const rawTitle = node.title || '(Sin título)';
        const cleanTitle = rawTitle.replace(/^(📋\s*)?(Especificación Funcional|Feature Specification|Bug Report|Spec)\s*[:—–-]\s*/i, '');
        const shortTitle = cleanTitle.length > 34 ? cleanTitle.substring(0, 34) + '...' : cleanTitle;
        const nodeLabel = `<b>${node.id}</b>\n${shortTitle}`;

        const row = Math.floor(idx / cols);
        const col = idx % cols;

        nodesArray.push({
          id: node.id,
          label: nodeLabel,
          title: `${node.id}: ${rawTitle}`,
          x: (col - cols / 2) * 260,
          y: (row - (nodes.length / cols) / 2) * 110,
          color: {
            background: '#0f172a',
            border: borderColor,
            highlight: { background: '#1e293b', border: '#38bdf8' },
            hover: { background: '#1e293b', border: '#7dd3fc' }
          },
          font: {
            color: '#f8fafc',
            size: 13,
            face: 'ui-sans-serif, system-ui, -apple-system, sans-serif',
            multi: 'html',
            bold: { color: '#38bdf8', size: 14, face: 'ui-monospace, monospace' }
          },
          shape: 'box',
          margin: { top: 12, right: 16, bottom: 12, left: 16 },
          borderWidth: 2,
          shadow: { enabled: true, color: 'rgba(0,0,0,0.6)', size: 8, x: 2, y: 3 },
          data: node
        });

        // Relaciones inline
        (node.depends_on || []).forEach(dep => {
          edgesArray.push({ from: node.id, to: dep, arrows: 'to', label: 'depends', color: { color: '#38bdf8', highlight: '#7dd3fc' }, font: { size: 10, color: '#94a3b8', strokeWidth: 0 } });
        });
        (node.supersedes || []).forEach(sup => {
          edgesArray.push({ from: node.id, to: sup, arrows: 'to', label: 'supersedes', dashes: true, color: { color: '#f59e0b' }, font: { size: 10, color: '#fbbf24', strokeWidth: 0 } });
        });
        (node.conflicts_with || []).forEach(conf => {
          edgesArray.push({ from: node.id, to: conf, arrows: 'to,from', label: 'conflicts', dashes: true, color: { color: '#f43f5e' }, font: { size: 10, color: '#f43f5e', strokeWidth: 0 } });
        });
      });

      (kgData.edges || []).forEach(edge => {
        edgesArray.push({
          from: edge.from,
          to: edge.to,
          arrows: 'to',
          label: edge.type || '',
          color: { color: edge.type === 'conflicts_with' ? '#f43f5e' : '#38bdf8' },
          font: { size: 10, color: '#94a3b8', strokeWidth: 0 }
        });
      });

      visNodes = new vis.DataSet(nodesArray);
      visEdges = new vis.DataSet(edgesArray);

      const data = { nodes: visNodes, edges: visEdges };
      const options = {
        nodes: {
          scaling: {
            label: {
              enabled: true,
              min: 9,
              max: 22,
              drawThreshold: 0
            }
          }
        },
        edges: {
          smooth: { type: 'cubicBezier', forceDirection: 'horizontal', roundness: 0.35 }
        },
        layout: { improvedLayout: false },
        physics: {
          enabled: true,
          solver: 'barnesHut',
          barnesHut: {
            gravitationalConstant: -1800,
            centralGravity: 0.4,
            springLength: 140,
            springConstant: 0.04,
            damping: 0.25,
            avoidOverlap: 0.8
          },
          stabilization: {
            enabled: true,
            iterations: 50,
            updateInterval: 20
          }
        },
        interaction: {
          hover: true,
          tooltipDelay: 100,
          zoomView: true,
          dragView: true,
          hideEdgesOnDrag: false,
          hideNodesOnDrag: false
        }
      };

      network = new vis.Network(container, data, options);

      network.on('click', function(params) {
        if (params.nodes.length > 0) {
          const selectedId = params.nodes[0];
          const nodeItem = visNodes.get(selectedId);
          showNodeDetails(nodeItem.data);
        } else {
          document.getElementById('node-detail-empty').classList.remove('hidden');
          document.getElementById('node-detail-card').classList.add('hidden');
        }
      });

      // Initial Camera: legible scale without extreme zoom-out
      setTimeout(() => {
        if (network) {
          network.moveTo({
            position: { x: 0, y: 0 },
            scale: 0.85,
            animation: { duration: 400 }
          });
        }
      }, 100);
    }

    function showNodeDetails(node) {
      if (!node) return;
      document.getElementById('node-detail-empty').classList.add('hidden');
      const card = document.getElementById('node-detail-card');
      card.classList.remove('hidden');

      document.getElementById('detail-id').textContent = node.id;
      document.getElementById('detail-title').textContent = node.title || '(Sin título)';
      
      const statusEl = document.getElementById('detail-status');
      statusEl.textContent = node.status || 'ACTIVE';
      statusEl.className = `px-2.5 py-0.5 rounded-full font-bold text-[10px] ${node.status === 'PENDING' ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' : (node.status === 'SUPERSEDED' ? 'bg-slate-700 text-slate-300' : 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30')}`;

      const formatRel = (arr) => {
        if (!arr || !Array.isArray(arr) || arr.length === 0) return '<span class="text-slate-500 text-xs italic">Ninguna</span>';
        return arr.map(item => {
          const val = typeof item === 'object' ? JSON.stringify(item) : item;
          return `<button onclick="focusNodeInGraph('${val}')" class="px-2 py-0.5 rounded bg-slate-800 hover:bg-sky-500/20 hover:text-sky-300 text-sky-400 font-mono text-[10px] inline-block mr-1 mb-1 border border-slate-700 transition">🔍 ${val}</button>`;
        }).join('');
      };

      document.getElementById('detail-depends').innerHTML = formatRel(node.depends_on);
      document.getElementById('detail-supersedes').innerHTML = formatRel(node.supersedes);
      document.getElementById('detail-conflicts').innerHTML = formatRel(node.conflicts_with);
    }

    function filterGraph(query) {
      currentGraphSearchQuery = (query || '').toLowerCase().trim();
      applyGraphCombinedFilters();
    }

    function setGraphTypeFilter(type) {
      currentGraphTypeFilter = type;
      document.querySelectorAll('.graph-filter-chip').forEach(btn => {
        btn.classList.remove('bg-sky-500', 'text-white', 'border-sky-400/30');
        btn.classList.add('bg-slate-800/80', 'text-slate-300', 'border-slate-700');
      });
      const activeBtn = document.getElementById('filter-graph-' + type.toLowerCase());
      if (activeBtn) {
        activeBtn.classList.remove('bg-slate-800/80', 'text-slate-300', 'border-slate-700');
        activeBtn.classList.add('bg-sky-500', 'text-white', 'border-sky-400/30');
      }
      applyGraphCombinedFilters();
    }

    function applyGraphCombinedFilters() {
      const q = currentGraphSearchQuery;
      const type = currentGraphTypeFilter;

      if (visNodes) {
        const allNodes = visNodes.get();
        allNodes.forEach(node => {
          const id = node.id.toLowerCase();
          const title = (node.data.title || '').toLowerCase();
          const matchesQuery = !q || id.includes(q) || title.includes(q);

          let matchesType = true;
          if (type === 'FEAT') {
            matchesType = !title.includes('bug') && !id.includes('bug');
          } else if (type === 'BUG') {
            matchesType = title.includes('bug') || id.includes('bug');
          }

          visNodes.update({ id: node.id, hidden: !(matchesQuery && matchesType) });
        });
      }

      renderAdrMatrix();
    }

    function zoomGraph(factor) {
      if (!network) return;
      const scale = network.getScale();
      network.moveTo({ scale: scale * factor, animation: { duration: 250 } });
    }

    function setGraphZoom100() {
      if (!network) return;
      network.moveTo({ scale: 1.0, animation: { duration: 300 } });
    }

    function resetGraphView() {
      if (!network) return;
      network.setSize('100%', '640px');
      network.redraw();
      network.fit({ animation: { duration: 350 } });
    }

    function reorganizeGraphGrid() {
      if (!visNodes || !network) return;
      const visibleNodes = visNodes.get({ filter: item => !item.hidden });
      const cols = Math.max(4, Math.ceil(Math.sqrt(visibleNodes.length * 1.5)));
      visibleNodes.forEach((node, idx) => {
        const row = Math.floor(idx / cols);
        const col = idx % cols;
        visNodes.update({
          id: node.id,
          x: (col - cols / 2) * 260,
          y: (row - (visibleNodes.length / cols) / 2) * 110
        });
      });
      network.moveTo({ scale: 0.85, animation: { duration: 300 } });
    }

    function setGraphViewMode(mode) {
      const btnCanvas = document.getElementById('btn-graph-mode-canvas');
      const btnMatrix = document.getElementById('btn-graph-mode-matrix');
      const viewCanvas = document.getElementById('graph-view-canvas');
      const viewMatrix = document.getElementById('graph-view-matrix');
      const zoomToolbar = document.getElementById('graph-zoom-toolbar');

      if (mode === 'canvas') {
        btnCanvas.className = 'px-3 py-1.5 rounded-lg bg-sky-500 text-white font-semibold shadow-sm transition flex items-center gap-1.5';
        btnMatrix.className = 'px-3 py-1.5 rounded-lg text-slate-400 hover:text-slate-200 transition flex items-center gap-1.5';
        viewCanvas.classList.remove('hidden');
        viewMatrix.classList.add('hidden');
        zoomToolbar.classList.remove('hidden');
        if (network) {
          network.setSize('100%', '640px');
          network.redraw();
        }
      } else {
        btnMatrix.className = 'px-3 py-1.5 rounded-lg bg-sky-500 text-white font-semibold shadow-sm transition flex items-center gap-1.5';
        btnCanvas.className = 'px-3 py-1.5 rounded-lg text-slate-400 hover:text-slate-200 transition flex items-center gap-1.5';
        viewCanvas.classList.add('hidden');
        viewMatrix.classList.remove('hidden');
        zoomToolbar.classList.add('hidden');
        renderAdrMatrix();
      }
    }

    function renderAdrMatrix() {
      const container = document.getElementById('adr-cards-grid');
      if (!container) return;
      const nodes = (kgData.nodes || []);
      const q = currentGraphSearchQuery;
      const type = currentGraphTypeFilter;

      const filtered = nodes.filter(node => {
        const id = (node.id || '').toLowerCase();
        const title = (node.title || '').toLowerCase();
        const matchesQuery = !q || id.includes(q) || title.includes(q);

        let matchesType = true;
        if (type === 'FEAT') matchesType = !title.includes('bug') && !id.includes('bug');
        if (type === 'BUG') matchesType = title.includes('bug') || id.includes('bug');

        return matchesQuery && matchesType;
      });

      if (filtered.length === 0) {
        container.innerHTML = `
          <div class="col-span-full py-16 text-center text-slate-500">
            <span class="text-3xl">🔍</span>
            <p class="mt-2 text-xs">No se encontraron decisiones que coincidan con los filtros aplicados.</p>
          </div>
        `;
        return;
      }

      container.innerHTML = filtered.map(node => {
        const isBug = (node.title || '').toLowerCase().includes('bug') || (node.id || '').toLowerCase().includes('bug');
        const statusBadge = node.status === 'PENDING' 
          ? '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-500/20 text-amber-400 border border-amber-500/30">PENDING</span>'
          : (node.status === 'SUPERSEDED' 
            ? '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-700 text-slate-300">SUPERSEDED</span>'
            : '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">ACTIVE</span>');
        
        const typeBadge = isBug 
          ? '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-rose-500/20 text-rose-300 border border-rose-500/30">🐛 BUG</span>'
          : '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-sky-500/20 text-sky-300 border border-sky-500/30">🚀 FEATURE</span>';

        return `
          <div class="bg-slate-900/90 border border-slate-800 hover:border-sky-500/40 p-4 rounded-xl flex flex-col justify-between transition group hover:shadow-lg hover:shadow-sky-500/5">
            <div>
              <div class="flex items-center justify-between gap-2 pb-2.5 border-b border-slate-800/80">
                <span class="font-mono font-bold text-xs text-sky-400">${node.id}</span>
                <div class="flex items-center gap-1.5">
                  ${typeBadge}
                  ${statusBadge}
                </div>
              </div>
              <h4 class="text-xs font-semibold text-slate-100 mt-2.5 leading-snug group-hover:text-sky-300 transition line-clamp-3">
                ${node.title || '(Sin título)'}
              </h4>
            </div>

            <div class="mt-4 pt-3 border-t border-slate-800/60 flex items-center justify-between text-[11px]">
              <span class="text-slate-500 font-mono">${(node.depends_on || []).length} deps</span>
              <button onclick="focusNodeInGraph('${node.id}')" class="px-2.5 py-1 bg-slate-800 hover:bg-sky-500 hover:text-white text-slate-300 rounded-lg text-[10px] font-medium transition flex items-center gap-1">
                <span>Ver en Grafo</span> <span>↗</span>
              </button>
            </div>
          </div>
        `;
      }).join('');
    }

    function focusNodeInGraph(nodeId) {
      setGraphViewMode('canvas');
      if (!network || !visNodes) return;
      const node = visNodes.get(nodeId);
      if (node) {
        network.focus(nodeId, {
          scale: 1.1,
          animation: { duration: 450, easingFunction: 'easeInOutQuad' }
        });
        network.selectNodes([nodeId]);
        showNodeDetails(node.data);
      }
    }

    // --- Telemetría & Live OpenRouter Pricing Engine ---
    let liveModelsPricing = [];
    let livePricingSyncTime = null;
    let chartRolesInst = null, chartPhasesInst = null, chartModelsInst = null;

    const fallbackPricingMap = {
      'gemini-3.7-flash': { prompt: 0.075 / 1e6, completion: 0.30 / 1e6, name: 'Gemini 3.7 Flash', provider: 'Google' },
      'gemini-2.5-pro': { prompt: 1.25 / 1e6, completion: 5.00 / 1e6, name: 'Gemini 2.5 Pro', provider: 'Google' },
      'claude-3-7-sonnet': { prompt: 3.00 / 1e6, completion: 15.00 / 1e6, name: 'Claude 3.7 Sonnet', provider: 'Anthropic' },
      'claude-3-5-sonnet': { prompt: 3.00 / 1e6, completion: 15.00 / 1e6, name: 'Claude 3.5 Sonnet', provider: 'Anthropic' },
      'claude-3-5-haiku': { prompt: 0.80 / 1e6, completion: 4.00 / 1e6, name: 'Claude 3.5 Haiku', provider: 'Anthropic' },
      'deepseek-r1': { prompt: 0.55 / 1e6, completion: 2.19 / 1e6, name: 'DeepSeek R1', provider: 'DeepSeek' },
      'deepseek-v3': { prompt: 0.14 / 1e6, completion: 0.28 / 1e6, name: 'DeepSeek V3', provider: 'DeepSeek' },
      'gpt-4o': { prompt: 2.50 / 1e6, completion: 10.00 / 1e6, name: 'GPT-4o', provider: 'OpenAI' },
      'gpt-4o-mini': { prompt: 0.15 / 1e6, completion: 0.60 / 1e6, name: 'GPT-4o Mini', provider: 'OpenAI' },
      'qwen-2.5-coder': { prompt: 0.66 / 1e6, completion: 1.00 / 1e6, name: 'Qwen 2.5 Coder', provider: 'Qwen' }
    };

    function matchModelPricing(modelName) {
      if (!modelName || modelName === 'null' || modelName === 'no-especificado') {
        // Fallback default: Gemini Flash / Baseline Económico ($0.10 in / $0.40 out por 1M)
        return { prompt: 0.10 / 1e6, completion: 0.40 / 1e6, name: 'Estándar (Estimado)', provider: 'General', isEstimated: true };
      }

      const q = modelName.toLowerCase().replace(/[-_./:]/g, '');
      
      // 1. Buscar en liveModelsPricing de OpenRouter
      if (liveModelsPricing && liveModelsPricing.length > 0) {
        // Coincidencia exacta o por subcadena normalizada
        const found = liveModelsPricing.find(m => {
          const normId = m.id.toLowerCase().replace(/[-_./:]/g, '');
          const normName = (m.name || '').toLowerCase().replace(/[-_./:]/g, '');
          return normId.includes(q) || normName.includes(q) || q.includes(normId);
        });
        if (found) {
          return {
            prompt: found.promptPrice,
            completion: found.completionPrice,
            name: found.name || found.id,
            provider: (found.id.split('/')[0] || 'OpenRouter').toUpperCase(),
            isEstimated: false
          };
        }
      }

      // 2. Buscar en fallback dictionary
      for (const [k, v] of Object.entries(fallbackPricingMap)) {
        const normK = k.toLowerCase().replace(/[-_./:]/g, '');
        if (normK.includes(q) || q.includes(normK)) {
          return { ...v, isEstimated: false };
        }
      }

      return { prompt: 0.20 / 1e6, completion: 0.80 / 1e6, name: modelName, provider: 'Desconocido', isEstimated: true };
    }

    async function refreshLivePricing(forceRefresh = false) {
      const dot = document.getElementById('pricing-status-dot');
      const text = document.getElementById('pricing-status-text');
      const countLabel = document.getElementById('pricing-models-count');
      const modalSyncTime = document.getElementById('modal-pricing-sync-time');

      if (dot) dot.className = 'inline-block w-2.5 h-2.5 rounded-full bg-amber-400 animate-spin';
      if (text) text.textContent = 'Consultando tarifas en vivo a OpenRouter API...';

      try {
        const cacheKey = 'ai_agents_openrouter_pricing_v1';
        const cacheTimeKey = 'ai_agents_openrouter_pricing_time';
        const cachedData = localStorage.getItem(cacheKey);
        const cachedTime = localStorage.getItem(cacheTimeKey);

        const isFresh = cachedTime && (Date.now() - Number(cachedTime) < 12 * 3600 * 1000); // 12h cache

        let rawModels = [];
        if (!forceRefresh && isFresh && cachedData) {
          rawModels = JSON.parse(cachedData);
          livePricingSyncTime = new Date(Number(cachedTime)).toLocaleTimeString();
        } else {
          const res = await fetch('https://openrouter.ai/api/v1/models', { headers: { 'User-Agent': 'ai-agents-os/3.5.0' } });
          if (!res.ok) throw new Error('HTTP ' + res.status);
          const json = await res.json();
          rawModels = json.data || [];
          localStorage.setItem(cacheKey, JSON.stringify(rawModels));
          localStorage.setItem(cacheTimeKey, String(Date.now()));
          livePricingSyncTime = new Date().toLocaleTimeString();
        }

        liveModelsPricing = rawModels.map(m => {
          const p = m.pricing || {};
          const pIn = parseFloat(p.prompt || 0);
          const pOut = parseFloat(p.completion || 0);
          return {
            id: m.id,
            name: m.name || m.id,
            promptPrice: isNaN(pIn) ? 0 : pIn,
            completionPrice: isNaN(pOut) ? 0 : pOut,
            provider: m.id.split('/')[0] || 'OpenRouter'
          };
        });

        if (dot) dot.className = 'inline-block w-2.5 h-2.5 rounded-full bg-emerald-400';
        if (text) text.textContent = 'Tarifas en vivo sincronizadas con OpenRouter API';
        if (countLabel) countLabel.textContent = `${liveModelsPricing.length} modelos activos`;
        if (modalSyncTime) modalSyncTime.textContent = `Última sincronización: ${livePricingSyncTime || 'Hoy'}`;

      } catch (err) {
        console.warn('OpenRouter API live fetch failed, using fallback pricing:', err);
        if (dot) dot.className = 'inline-block w-2.5 h-2.5 rounded-full bg-sky-400';
        if (text) text.textContent = 'Tarifas cargadas desde base local (offline)';
        if (countLabel) countLabel.textContent = `${Object.keys(fallbackPricingMap).length} modelos`;
        if (modalSyncTime) modalSyncTime.textContent = 'Modo offline / Base de referencia local';
      }

      renderTelemetryWithPricing();
      renderPricingTable();
    }

    function initMetrics() {
      refreshLivePricing(false);
    }

    let currentEnvFilter = 'ALL';
    let chartEnvironmentsInst = null;

    function setEnvFilter(env) {
      currentEnvFilter = env;
      document.querySelectorAll('.filter-env-btn').forEach(btn => btn.classList.remove('active', 'bg-sky-600', 'text-white'));
      const activeBtn = document.getElementById('filter-env-' + env);
      if (activeBtn) activeBtn.classList.add('active');
      renderTelemetryWithPricing();
    }

    function renderTelemetryWithPricing() {
      const executions = metricsData.executions || [];
      let totalIn = 0, totalOut = 0, totalSec = 0, retries = 0;
      let totalCostUsd = 0;
      let measuredExecsCount = 0;
      const roleTokens = {};
      const phaseTokens = {};
      const modelTokens = {};
      const modelCosts = {};
      const envTokens = { 'local': 0, 'staging': 0, 'production': 0 };

      executions.forEach(ex => {
        const hasTokIn = ex.tokens_in !== null && ex.tokens_in !== undefined && ex.tokens_in !== '' && !isNaN(Number(ex.tokens_in));
        const hasTokOut = ex.tokens_out !== null && ex.tokens_out !== undefined && ex.tokens_out !== '' && !isNaN(Number(ex.tokens_out));
        const inTok = hasTokIn ? Number(ex.tokens_in) : 0;
        const outTok = hasTokOut ? Number(ex.tokens_out) : 0;
        const sum = inTok + outTok;

        const pricing = matchModelPricing(ex.model);
        const sessionCost = (inTok * pricing.prompt) + (outTok * pricing.completion);
        ex._computedCost = sessionCost;
        ex._matchedModel = pricing.name;
        ex._matchedProvider = pricing.provider;

        const env = ex.target_env || 'local';
        envTokens[env] = (envTokens[env] || 0) + (sum > 0 ? sum : 1);

        if (sum > 0 || (hasTokIn && inTok > 0) || (hasTokOut && outTok > 0)) {
          totalIn += inTok;
          totalOut += outTok;
          totalCostUsd += sessionCost;
          measuredExecsCount++;

          const role = ex.role || 'desconocido';
          const phase = ex.phase || 'otras';
          const modelKey = ex.model && ex.model !== 'null' ? ex.model : 'No especificado';

          roleTokens[role] = (roleTokens[role] || 0) + sum;
          phaseTokens[phase] = (phaseTokens[phase] || 0) + sum;
          modelTokens[modelKey] = (modelTokens[modelKey] || 0) + sum;
          modelCosts[modelKey] = (modelCosts[modelKey] || 0) + sessionCost;
        }

        if (ex.duration_s !== null && ex.duration_s !== undefined && ex.duration_s !== '' && !isNaN(Number(ex.duration_s)) && Number(ex.duration_s) > 0) {
          totalSec += Number(ex.duration_s);
        }
        if (Number(ex.attempts) > 1) retries += (Number(ex.attempts) - 1);
      });

      const totalTokens = totalIn + totalOut;
      const avgTokens = measuredExecsCount > 0 ? Math.round(totalTokens / measuredExecsCount) : 0;
      const ratioIn = totalTokens > 0 ? Math.round((totalIn / totalTokens) * 100) : 0;
      const ratioOut = totalTokens > 0 ? (100 - ratioIn) : 0;

      // Banner de estado vacío
      const emptyBanner = document.getElementById('metrics-empty-banner');
      if (emptyBanner) {
        if (totalTokens === 0 && executions.length > 0) {
          emptyBanner.classList.remove('hidden');
          emptyBanner.classList.add('flex');
        } else {
          emptyBanner.classList.add('hidden');
          emptyBanner.classList.remove('flex');
        }
      }

      // KPIs
      document.getElementById('kpi-tokens-total').textContent = totalTokens > 0 ? totalTokens.toLocaleString() : '—';
      document.getElementById('kpi-tokens-in').textContent = totalIn > 0 ? totalIn.toLocaleString() : '—';
      document.getElementById('kpi-tokens-out').textContent = totalOut > 0 ? totalOut.toLocaleString() : '—';
      
      const costEl = document.getElementById('kpi-cost-total');
      if (costEl) {
        costEl.textContent = totalCostUsd > 0 ? `$${totalCostUsd.toFixed(4)}` : (totalTokens > 0 ? '< $0.01' : '—');
      }

      document.getElementById('kpi-tokens-avg').textContent = avgTokens > 0 ? avgTokens.toLocaleString() : '—';
      document.getElementById('kpi-tokens-ratio').textContent = totalTokens > 0 ? `${ratioIn}% in · ${ratioOut}% out` : '—';
      document.getElementById('kpi-sessions').textContent = executions.length;
      document.getElementById('kpi-retries').textContent = retries;
      document.getElementById('kpi-time').textContent = totalSec > 0 ? (Math.round(totalSec / 60) + ' min') : '—';

      // Destroy previous chart instances
      if (chartRolesInst) chartRolesInst.destroy();
      if (chartPhasesInst) chartPhasesInst.destroy();
      if (chartModelsInst) chartModelsInst.destroy();
      if (chartEnvironmentsInst) chartEnvironmentsInst.destroy();

      // Chart 1: Roles
      const roleLabels = Object.keys(roleTokens).length > 0 ? Object.keys(roleTokens) : ['Sin telemetría'];
      const roleValues = Object.keys(roleTokens).length > 0 ? Object.values(roleTokens) : [1];
      const roleColors = Object.keys(roleTokens).length > 0 ? ['#0ea5e9', '#6366f1', '#10b981', '#f59e0b', '#ec4899', '#8b5cf6'] : ['#334155'];

      chartRolesInst = new Chart(document.getElementById('chart-roles'), {
        type: 'doughnut',
        data: {
          labels: roleLabels,
          datasets: [{ data: roleValues, backgroundColor: roleColors }]
        },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8', font: { size: 10 } } } } }
      });

      // Chart 2: Phases
      const phaseLabels = Object.keys(phaseTokens).length > 0 ? Object.keys(phaseTokens) : ['Sin telemetría'];
      const phaseValues = Object.keys(phaseTokens).length > 0 ? Object.values(phaseTokens) : [0];

      chartPhasesInst = new Chart(document.getElementById('chart-phases'), {
        type: 'bar',
        data: {
          labels: phaseLabels,
          datasets: [{ label: 'Tokens', data: phaseValues, backgroundColor: '#38bdf8', borderRadius: 6 }]
        },
        options: { responsive: true, maintainAspectRatio: false, scales: { x: { ticks: { color: '#94a3b8' } }, y: { ticks: { color: '#94a3b8' } } }, plugins: { legend: { display: false } } }
      });

      // Chart 3: Models
      const modelLabels = Object.keys(modelTokens).length > 0 ? Object.keys(modelTokens) : ['Sin telemetría'];
      const modelValues = Object.keys(modelTokens).length > 0 ? Object.values(modelTokens) : [1];
      const modelColors = ['#10b981', '#38bdf8', '#818cf8', '#f59e0b', '#ec4899'];

      chartModelsInst = new Chart(document.getElementById('chart-models'), {
        type: 'doughnut',
        data: {
          labels: modelLabels,
          datasets: [{ data: modelValues, backgroundColor: modelColors.slice(0, modelLabels.length) }]
        },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8', font: { size: 10 } } } } }
      });

      // Chart 4: Environments
      const envLabels = ['Local', 'Staging', 'Producción'];
      const envValues = [envTokens['local'] || 0, envTokens['staging'] || 0, envTokens['production'] || 0];
      const envColors = ['#38bdf8', '#f59e0b', '#10b981'];

      chartEnvironmentsInst = new Chart(document.getElementById('chart-environments'), {
        type: 'doughnut',
        data: {
          labels: envLabels,
          datasets: [{ data: envValues, backgroundColor: envColors }]
        },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8', font: { size: 10 } } } } }
      });

      // Filter Executions for Table
      let tableExecutions = executions.slice();
      if (currentEnvFilter !== 'ALL') {
        tableExecutions = tableExecutions.filter(ex => (ex.target_env || 'local') === currentEnvFilter);
      }

      // Populate Table
      const tbody = document.getElementById('executions-tbody');
      tbody.innerHTML = '';
      document.getElementById('table-count').textContent = tableExecutions.length + ' de ' + executions.length + ' ejecuciones';
      
      tableExecutions.reverse().forEach(ex => {
        const tr = document.createElement('tr');
        tr.className = 'hover:bg-slate-800/40 transition';
        const tsFormatted = formatTimestamp(ex.ts);
        const hasTokIn = ex.tokens_in !== null && ex.tokens_in !== undefined && ex.tokens_in !== '' && !isNaN(Number(ex.tokens_in));
        const hasTokOut = ex.tokens_out !== null && ex.tokens_out !== undefined && ex.tokens_out !== '' && !isNaN(Number(ex.tokens_out));
        const hasDur = ex.duration_s !== null && ex.duration_s !== undefined && ex.duration_s !== '' && !isNaN(Number(ex.duration_s)) && Number(ex.duration_s) > 0;
        
        const tokInFormatted = hasTokIn ? Number(ex.tokens_in).toLocaleString() : '—';
        const tokOutFormatted = hasTokOut ? Number(ex.tokens_out).toLocaleString() : '—';
        const durFormatted = hasDur ? `${Number(ex.duration_s)}s` : '—';
        const costFormatted = (hasTokIn || hasTokOut) && ex._computedCost !== undefined
          ? `$${ex._computedCost.toFixed(4)}`
          : '—';
        
        const modelLabel = ex.model && ex.model !== 'null' ? ex.model : (ex.provider && ex.provider !== 'null' ? ex.provider : '—');
        
        const env = ex.target_env || 'local';
        let envBadgeClass = 'bg-sky-500/20 text-sky-400 border border-sky-500/30';
        let envIcon = '💻';
        if (env === 'staging') { envBadgeClass = 'bg-amber-500/20 text-amber-400 border border-amber-500/30'; envIcon = '🌐'; }
        if (env === 'production') { envBadgeClass = 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'; envIcon = '🚀'; }

        const gitBranchHtml = ex.git_branch && ex.git_branch !== 'null'
          ? `<div class="text-[9px] text-slate-500 font-mono mt-0.5 truncate max-w-[130px]" title="${ex.git_branch}">🌿 ${ex.git_branch}</div>`
          : '';

        const verdict = ex.verdict || '-';
        let verdictClass = 'bg-slate-800 text-slate-400';
        if (verdict === 'APROBADO' || verdict === 'PASS') verdictClass = 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30';
        if (verdict === 'RECHAZADO' || verdict === 'FAIL') verdictClass = 'bg-rose-500/20 text-rose-400 border border-rose-500/30';

        tr.innerHTML = `
          <td class="py-3 px-4 text-slate-400 whitespace-nowrap">${tsFormatted}</td>
          <td class="py-3 px-4 font-bold text-sky-400 whitespace-nowrap">${ex.initiative || '-'}</td>
          <td class="py-3 px-4 text-slate-300 capitalize">${ex.role || '-'}</td>
          <td class="py-3 px-4 text-slate-400">${ex.phase || '-'}</td>
          <td class="py-3 px-4 text-slate-300 font-mono text-[10px]">${modelLabel}</td>
          <td class="py-3 px-4 whitespace-nowrap">
            <span class="px-2 py-0.5 rounded text-[10px] font-bold ${envBadgeClass}">${envIcon} ${env}</span>
            ${gitBranchHtml}
          </td>
          <td class="py-3 px-4 text-slate-400">${tokInFormatted}</td>
          <td class="py-3 px-4 text-slate-400">${tokOutFormatted}</td>
          <td class="py-3 px-4 font-bold text-emerald-400">${costFormatted}</td>
          <td class="py-3 px-4 text-slate-400">${durFormatted}</td>
          <td class="py-3 px-4"><span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold ${verdictClass}">${verdict}</span></td>
        `;
        tbody.appendChild(tr);
      });
    }

    function openCostMethodologyModal() {
      const modal = document.getElementById('cost-methodology-modal');
      if (modal) modal.classList.remove('hidden');
      renderPricingTable();
    }

    function closeCostMethodologyModal() {
      const modal = document.getElementById('cost-methodology-modal');
      if (modal) modal.classList.add('hidden');
    }

    function renderPricingTable(searchFilter = '') {
      const tbody = document.getElementById('pricing-tbody');
      if (!tbody) return;

      const filter = searchFilter.toLowerCase().trim();
      let list = (liveModelsPricing && liveModelsPricing.length > 0)
        ? liveModelsPricing
        : Object.entries(fallbackPricingMap).map(([k, v]) => ({ id: k, name: v.name, promptPrice: v.prompt, completionPrice: v.completion, provider: v.provider }));

      if (filter) {
        list = list.filter(m => m.id.toLowerCase().includes(filter) || (m.name || '').toLowerCase().includes(filter) || (m.provider || '').toLowerCase().includes(filter));
      }

      // Priorizar los modelos más populares
      const topPriority = ['gemini-3.7-flash', 'gemini-2.5-flash', 'claude-3.7-sonnet', 'claude-3.5-sonnet', 'deepseek-r1', 'gpt-4o', 'qwen-2.5-coder'];
      list.sort((a, b) => {
        const aTop = topPriority.some(p => a.id.toLowerCase().includes(p));
        const bTop = topPriority.some(p => b.id.toLowerCase().includes(p));
        if (aTop && !bTop) return -1;
        if (!aTop && bTop) return 1;
        return a.id.localeCompare(b.id);
      });

      const displayList = list.slice(0, 50);

      tbody.innerHTML = displayList.map(m => {
        const prompt1M = (m.promptPrice * 1_000_000).toFixed(3);
        const compl1M = (m.completionPrice * 1_000_000).toFixed(3);
        return `
          <tr class="hover:bg-slate-800/50 transition">
            <td class="py-2.5 px-3">
              <div class="font-bold text-slate-200">${m.name || m.id}</div>
              <div class="text-[9px] text-slate-500 font-mono">${m.id}</div>
            </td>
            <td class="py-2.5 px-3 font-mono text-sky-300">$${prompt1M}</td>
            <td class="py-2.5 px-3 font-mono text-emerald-300">$${compl1M}</td>
            <td class="py-2.5 px-3 text-slate-400 uppercase text-[10px]">${m.provider}</td>
          </tr>
        `;
      }).join('');
    }

    function filterPricingTable() {
      const q = (document.getElementById('pricing-search-input')?.value || '');
      renderPricingTable(q);
    }

    // --- Business Rules & Memory Rendering ---
    function initDocsAndMemory() {
      document.getElementById('rules-content').innerHTML = marked.parse(rulesRaw);
      document.getElementById('glossary-content').innerHTML = marked.parse(glossaryRaw);
      document.getElementById('snapshot-content').innerHTML = marked.parse(snapshotRaw);
      document.getElementById('catalog-content').innerHTML = marked.parse(catalogRaw);
      document.getElementById('patterns-content').innerHTML = marked.parse(patternsRaw);

      // Workflow Log Timeline Cards
      const timelineContainer = document.getElementById('log-timeline');
      const logSections = logRaw.split(/^## /m).filter(s => s.trim().length > 0);
      
      logSections.forEach((section, index) => {
        if (index === 0 && section.includes('Memoria Episódica')) return; // Header
        const lines = section.split('\n');
        const header = lines[0];
        const body = lines.slice(1).join('\n');

        const card = document.createElement('div');
        card.className = 'bg-slate-950/70 border border-slate-800/80 p-5 rounded-2xl space-y-2 border-l-4 border-l-sky-500 shadow-sm';
        card.innerHTML = `
          <h4 class="text-xs font-bold text-slate-200">${header}</h4>
          <div class="prose prose-invert max-w-none w-full text-xs">${marked.parse(body)}</div>
        `;
        timelineContainer.appendChild(card);
      });
    }

    // ==================== INITIATIVES CONTROLLER WITH PAGINATION ====================
    let currentTypeFilter = 'ALL';
    let currentStatusFilter = 'ALL';
    let currentQaFilter = 'ALL';
    let currentPage = 1;
    let pageSize = 12;

    function setTypeFilter(type) {
      currentTypeFilter = type;
      document.querySelectorAll('.filter-type-btn').forEach(btn => btn.classList.remove('active'));
      document.getElementById('filter-type-' + type).classList.add('active');
      currentPage = 1;
      applyInitiativeFilters();
    }

    function setStatusFilter(status) {
      currentStatusFilter = status;
      document.querySelectorAll('.filter-status-btn').forEach(btn => btn.classList.remove('active'));
      document.getElementById('filter-status-' + status).classList.add('active');
      currentPage = 1;
      applyInitiativeFilters();
    }

    function setQaFilter(qa) {
      currentQaFilter = qa;
      document.querySelectorAll('.filter-qa-btn').forEach(btn => btn.classList.remove('active'));
      document.getElementById('filter-qa-' + qa).classList.add('active');
      currentPage = 1;
      applyInitiativeFilters();
    }

    function changePageSize(size) {
      pageSize = size === 'all' ? 999999 : parseInt(size, 10);
      currentPage = 1;
      applyInitiativeFilters();
    }

    function goToPage(page) {
      currentPage = page;
      applyInitiativeFilters();
      const tabEl = document.getElementById('tab-features');
      if (tabEl) {
        tabEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    }

    function initInitiatives() {
      // Normalizador de ID (ej: BUG-075-slug -> BUG-075)
      const normalizeInitId = (idStr) => {
        if (!idStr) return '';
        const match = idStr.trim().match(/^([A-Z]+-\d+)/i);
        return match ? match[1].toUpperCase() : idStr.trim().toUpperCase();
      };

      // Cruzar métricas reales con iniciativas
      const initMetrics = {};
      (metricsData.executions || []).forEach(ex => {
        if (!ex.initiative) return;
        const normKey = normalizeInitId(ex.initiative);
        const rawKey = ex.initiative.trim();
        
        [normKey, rawKey].forEach(k => {
          if (!k) return;
          if (!initMetrics[k]) initMetrics[k] = { count: 0, tokensIn: 0, tokensOut: 0, totalTokens: 0, hasMeasuredTokens: false, executions: [], lastTs: ex.ts };
        });

        const hasTokIn = ex.tokens_in !== null && ex.tokens_in !== undefined && ex.tokens_in !== '' && !isNaN(Number(ex.tokens_in));
        const hasTokOut = ex.tokens_out !== null && ex.tokens_out !== undefined && ex.tokens_out !== '' && !isNaN(Number(ex.tokens_out));
        const inTok = hasTokIn ? Number(ex.tokens_in) : 0;
        const outTok = hasTokOut ? Number(ex.tokens_out) : 0;
        const sum = inTok + outTok;
        const isMeasured = (sum > 0 || (hasTokIn && inTok > 0) || (hasTokOut && outTok > 0));

        const target = initMetrics[normKey];
        target.count++;
        if (isMeasured) {
          target.tokensIn += inTok;
          target.tokensOut += outTok;
          target.totalTokens += sum;
          target.hasMeasuredTokens = true;
        }
        target.executions.push(ex);
        target.lastTs = ex.ts;

        if (rawKey !== normKey) {
          const rawTarget = initMetrics[rawKey];
          rawTarget.count++;
          if (isMeasured) {
            rawTarget.tokensIn += inTok;
            rawTarget.tokensOut += outTok;
            rawTarget.totalTokens += sum;
            rawTarget.hasMeasuredTokens = true;
          }
          rawTarget.executions.push(ex);
          rawTarget.lastTs = ex.ts;
        }
      });

      // Asignar métricas a la lista de iniciativas
      allInitiatives.forEach(init => {
        const normId = normalizeInitId(init.id);
        const met = initMetrics[normId] || initMetrics[init.id] || { count: 0, tokensIn: 0, tokensOut: 0, totalTokens: 0, hasMeasuredTokens: false, executions: [], lastTs: '-' };
        init.metrics = met;
      });

      // Calcular KPI Cards
      let activeCount = 0, archivedCount = 0, featsCount = 0, bugsCount = 0, approvedCount = 0;
      allInitiatives.forEach(init => {
        if (init.status === 'ACTIVE') activeCount++;
        if (init.status === 'ARCHIVED') archivedCount++;
        if (init.type === 'FEAT') featsCount++;
        if (init.type === 'BUG') bugsCount++;
        if (init.qa_verdict === 'APROBADO') approvedCount++;
      });

      document.getElementById('init-kpi-total').textContent = allInitiatives.length;
      document.getElementById('init-kpi-active').textContent = activeCount;
      document.getElementById('init-kpi-archived').textContent = archivedCount;
      document.getElementById('init-kpi-feats').textContent = featsCount;
      document.getElementById('init-kpi-bugs').textContent = bugsCount;
      document.getElementById('init-kpi-approved').textContent = approvedCount;

      applyInitiativeFilters();
    }

    function applyInitiativeFilters() {
      const search = (document.getElementById('init-search-input').value || '').toLowerCase().trim();
      const sort = document.getElementById('init-sort-select').value;
      const grid = document.getElementById('initiatives-grid');
      grid.innerHTML = '';

      let filtered = allInitiatives.filter(item => {
        // Search
        if (search) {
          const matchId = item.id.toLowerCase().includes(search);
          const matchTitle = (item.title || '').toLowerCase().includes(search);
          if (!matchId && !matchTitle) return false;
        }

        // Type
        if (currentTypeFilter !== 'ALL' && item.type !== currentTypeFilter) return false;

        // Status
        if (currentStatusFilter === 'READY_TO_ARCHIVE') {
          if (!(item.status === 'ACTIVE' && item.qa_verdict === 'APROBADO')) return false;
        } else if (currentStatusFilter !== 'ALL' && item.status !== currentStatusFilter) {
          return false;
        }

        // QA
        if (currentQaFilter === 'APROBADO' && item.qa_verdict !== 'APROBADO') return false;
        if (currentQaFilter === 'PENDING' && item.qa_verdict === 'APROBADO') return false;

        return true;
      });

      // Sorting
      filtered.sort((a, b) => {
        if (sort === 'id-asc') return a.id.localeCompare(b.id, undefined, { numeric: true });
        if (sort === 'id-desc') return b.id.localeCompare(a.id, undefined, { numeric: true });
        if (sort === 'tokens-desc') return (b.metrics.totalTokens || 0) - (a.metrics.totalTokens || 0);
        if (sort === 'tokens-asc') return (a.metrics.totalTokens || 0) - (b.metrics.totalTokens || 0);
        if (sort === 'title-asc') return (a.title || '').localeCompare(b.title || '');
        return 0;
      });

      currentFilteredInitiatives = filtered;

      // Pagination Calculation
      const totalItems = filtered.length;
      const totalPages = Math.ceil(totalItems / pageSize) || 1;
      if (currentPage > totalPages) currentPage = totalPages;
      if (currentPage < 1) currentPage = 1;

      const startIndex = (currentPage - 1) * pageSize;
      const endIndex = Math.min(startIndex + pageSize, totalItems);
      const pageItems = pageSize >= 99999 ? filtered : filtered.slice(startIndex, endIndex);

      // Update Feedback Counter
      document.getElementById('initiatives-count-label').textContent = `Mostrando ${totalItems === 0 ? 0 : startIndex + 1}–${endIndex} de ${totalItems} iniciativas (Total: ${allInitiatives.length})`;
      document.getElementById('pagination-info').textContent = `Página ${currentPage} de ${totalPages} (${totalItems} items)`;

      renderPaginationButtons(totalPages);

      if (pageItems.length === 0) {
        grid.innerHTML = `
          <div class="col-span-full py-16 text-center text-slate-500 bg-slate-900/40 border border-slate-800 rounded-2xl">
            <span class="text-3xl block">🔍</span>
            <p class="mt-2 text-xs">No se encontraron iniciativas que coincidan con los filtros seleccionados.</p>
          </div>
        `;
        return;
      }

      pageItems.forEach((init, idx) => {
        const card = document.createElement('div');
        card.className = 'bg-slate-900/90 border border-slate-800/80 hover:border-sky-500/50 hover:bg-slate-900 transition-all duration-200 rounded-2xl p-5 sm:p-5.5 flex flex-col justify-between space-y-4 shadow-md hover:shadow-xl relative overflow-hidden group';

        // Type color badge
        let typeBadgeClass = 'bg-sky-500/20 text-sky-400 border border-sky-500/30';
        if (init.type === 'BUG') typeBadgeClass = 'bg-rose-500/20 text-rose-400 border border-rose-500/30';
        if (init.type === 'AUDIT') typeBadgeClass = 'bg-purple-500/20 text-purple-400 border border-purple-500/30';
        if (init.type === 'REF') typeBadgeClass = 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30';

        // QA badge
        let qaBadgeClass = 'bg-amber-500/20 text-amber-400 border border-amber-500/30';
        let qaText = '🟡 QA: PENDIENTE';
        if (init.qa_verdict === 'APROBADO') {
          qaBadgeClass = 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30';
          qaText = '🟢 QA: APROBADO';
        } else if (init.qa_verdict === 'RECHAZADO') {
          qaBadgeClass = 'bg-rose-500/20 text-rose-400 border border-rose-500/30';
          qaText = '🔴 QA: RECHAZADO';
        }

        const isReadyToArchive = (init.status === 'ACTIVE' && init.qa_verdict === 'APROBADO');

        // Artifact chips helper
        const chip = (label, active, icon) => `
          <span class="px-2 py-0.5 rounded-md text-[10px] font-mono flex items-center gap-1 ${active ? 'bg-slate-800 text-sky-300 border border-sky-500/30' : 'bg-slate-950/60 text-slate-600 border border-slate-800/80'}">
            <span>${icon}</span>
            <span>${label}</span>
          </span>
        `;

        // Execution phase pills
        const executedPhases = [...new Set((init.metrics.executions || []).map(e => e.phase))];
        const phasePillsHtml = executedPhases.length > 0 ? `
          <div class="flex items-center gap-1 flex-wrap pt-1 text-[9px] font-mono text-slate-400">
            <span class="text-slate-500">Fases:</span>
            ${executedPhases.map(p => `<span class="px-1.5 py-0.2 rounded bg-slate-950/80 border border-slate-700/60 text-sky-300">${p}</span>`).join('<span class="text-slate-600">›</span>')}
          </div>
        ` : '';

        card.innerHTML = `
          <div class="space-y-3">
            <!-- Header Badges -->
            <div class="flex items-center justify-between gap-2 flex-wrap">
              <div class="flex items-center gap-1.5 flex-wrap">
                <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold ${typeBadgeClass}">${init.type}</span>
                <span class="px-2.5 py-0.5 rounded-full text-[10px] ${init.status === 'ACTIVE' ? 'bg-emerald-950/60 text-emerald-400 border border-emerald-800/40' : 'bg-slate-800 text-slate-400'}">${init.status === 'ACTIVE' ? 'Activa' : 'Archivada'}</span>
                ${isReadyToArchive ? '<span class="px-2 py-0.5 rounded-full text-[9px] font-bold bg-amber-500/20 text-amber-300 border border-amber-500/40">📦 Listo para Archivar</span>' : ''}
              </div>
              <span class="px-2.5 py-0.5 rounded-full text-[10px] font-semibold ${qaBadgeClass}">${qaText}</span>
            </div>

            <!-- ID and Title -->
            <div class="cursor-pointer" onclick="openInitiativeModalById('${init.id}')">
              <span class="font-mono text-xs font-bold text-sky-400 block group-hover:text-sky-300 transition">${init.id}</span>
              <h3 class="text-xs font-semibold text-slate-200 mt-1 line-clamp-2 leading-relaxed" title="${init.title}">${init.title}</h3>
            </div>

            <!-- SDD Artifacts Checklist -->
            <div class="flex flex-wrap gap-1.5 pt-1">
              ${chip(init.type === 'BUG' ? 'bug-report' : 'spec', init.has_spec || init.has_bug, '📄')}
              ${chip('ui', init.has_ui, '🎨')}
              ${chip('arch', init.has_arch, '🏗️')}
              ${chip('qa', init.has_qa, '🧪')}
              ${chip('dec', init.has_decision, '⚖️')}
            </div>

            ${phasePillsHtml}
          </div>

          <!-- Card Footer & Actions -->
          <div class="border-t border-slate-800/80 pt-3 flex items-center justify-between text-xs">
            <div class="text-[11px] text-slate-400">
              ${init.metrics.hasMeasuredTokens ? `
                <span class="font-bold text-slate-200">${(init.metrics.totalTokens || 0).toLocaleString()}</span> tokens
                <span class="text-slate-500">(${init.metrics.count || 0} fases)</span>
              ` : (init.metrics.count > 0 ? `
                <span class="text-slate-500 font-medium">— tokens</span>
                <span class="text-slate-600">(${init.metrics.count} fases)</span>
              ` : `
                <span class="text-slate-500 font-medium">— sin telemetría</span>
              `)}
            </div>
            <button onclick="openInitiativeModalById('${init.id}')" class="px-3.5 py-1.5 bg-slate-800 hover:bg-sky-600 hover:text-white text-slate-200 font-medium rounded-xl text-xs transition border border-slate-700/80 shadow-sm flex items-center gap-1.5">
              <span>Ver Detalle</span>
              <span>→</span>
            </button>
          </div>
        `;
        grid.appendChild(card);
      });
    }

    function renderPaginationButtons(totalPages) {
      const container = document.getElementById('pagination-buttons');
      container.innerHTML = '';

      if (totalPages <= 1) {
        document.getElementById('initiatives-pagination').classList.add('hidden');
        return;
      }
      document.getElementById('initiatives-pagination').classList.remove('hidden');

      // Prev button
      const prevBtn = document.createElement('button');
      prevBtn.className = `px-2.5 py-1 text-xs rounded-lg border border-slate-700/80 font-semibold transition ${currentPage === 1 ? 'opacity-40 cursor-not-allowed bg-slate-900 text-slate-600' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`;
      prevBtn.textContent = '‹ Ant';
      prevBtn.disabled = currentPage === 1;
      prevBtn.onclick = () => goToPage(currentPage - 1);
      container.appendChild(prevBtn);

      // Determine visible page numbers
      let pages = [];
      if (totalPages <= 7) {
        for (let i = 1; i <= totalPages; i++) pages.push(i);
      } else {
        pages.push(1);
        if (currentPage > 3) pages.push('...');
        const start = Math.max(2, currentPage - 1);
        const end = Math.min(totalPages - 1, currentPage + 1);
        for (let i = start; i <= end; i++) {
          if (!pages.includes(i)) pages.push(i);
        }
        if (currentPage < totalPages - 2) pages.push('...');
        if (!pages.includes(totalPages)) pages.push(totalPages);
      }

      pages.forEach(p => {
        if (p === '...') {
          const span = document.createElement('span');
          span.className = 'px-2 py-1 text-xs text-slate-600';
          span.textContent = '...';
          container.appendChild(span);
        } else {
          const btn = document.createElement('button');
          btn.className = `px-3 py-1 text-xs rounded-lg border font-semibold transition ${p === currentPage ? 'bg-sky-500 border-sky-400 text-white shadow-sm' : 'bg-slate-800 border-slate-700/80 text-slate-300 hover:bg-slate-700'}`;
          btn.textContent = p;
          btn.onclick = () => goToPage(p);
          container.appendChild(btn);
        }
      });

      // Next button
      const nextBtn = document.createElement('button');
      nextBtn.className = `px-2.5 py-1 text-xs rounded-lg border border-slate-700/80 font-semibold transition ${currentPage === totalPages ? 'opacity-40 cursor-not-allowed bg-slate-900 text-slate-600' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`;
      nextBtn.textContent = 'Sig ›';
      nextBtn.disabled = currentPage === totalPages;
      nextBtn.onclick = () => goToPage(currentPage + 1);
      container.appendChild(nextBtn);
    }

    // Modal Sub-Tabs
    function switchModalTab(tabName) {
      document.querySelectorAll('.modal-tab-btn').forEach(btn => {
        btn.classList.remove('border-sky-500', 'text-sky-400');
        btn.classList.add('border-transparent', 'text-slate-400');
      });
      const activeBtn = document.getElementById('modal-tab-btn-' + tabName);
      if (activeBtn) {
        activeBtn.classList.remove('border-transparent', 'text-slate-400');
        activeBtn.classList.add('border-sky-500', 'text-sky-400');
      }

      document.getElementById('modal-tab-artifacts').classList.toggle('hidden', tabName !== 'artifacts');
      document.getElementById('modal-tab-telemetry').classList.toggle('hidden', tabName !== 'telemetry');
      document.getElementById('modal-tab-cli').classList.toggle('hidden', tabName !== 'cli');
    }

    // Modal Manager
    function openInitiativeModalById(id) {
      const index = currentFilteredInitiatives.findIndex(i => i.id === id);
      if (index !== -1) {
        currentModalIndex = index;
        renderInitiativeModalData(currentFilteredInitiatives[index]);
      } else {
        const init = allInitiatives.find(i => i.id === id);
        if (init) renderInitiativeModalData(init);
      }
    }

    function navigateModal(direction) {
      if (currentModalIndex === -1 || currentFilteredInitiatives.length === 0) return;
      let nextIndex = currentModalIndex + direction;
      if (nextIndex < 0) nextIndex = currentFilteredInitiatives.length - 1;
      if (nextIndex >= currentFilteredInitiatives.length) nextIndex = 0;
      currentModalIndex = nextIndex;
      renderInitiativeModalData(currentFilteredInitiatives[nextIndex]);
    }

    function renderInitiativeModalData(init) {
      if (!init) return;

      document.getElementById('modal-title').textContent = init.id;
      document.getElementById('modal-desc').textContent = init.title || '';
      
      const folderPath = (init.status === 'ACTIVE' ? '.ai/features/' : '.ai/archive/') + init.id;
      document.getElementById('modal-folder-path').textContent = folderPath;
      document.getElementById('modal-folder-path-display').textContent = folderPath;

      // Update CLI snippet commands
      document.getElementById('modal-cmd-code').textContent = `code ${folderPath}`;
      document.getElementById('modal-cmd-finish').textContent = `bash .ai/agents/scripts/finish-phase.sh ${init.id} spec analyst`;

      // Type Badge
      const typeBadge = document.getElementById('modal-type-badge');
      typeBadge.textContent = init.type;
      let typeClass = 'bg-sky-500/20 text-sky-400 border border-sky-500/30';
      if (init.type === 'BUG') typeClass = 'bg-rose-500/20 text-rose-400 border border-rose-500/30';
      if (init.type === 'AUDIT') typeClass = 'bg-purple-500/20 text-purple-400 border border-purple-500/30';
      if (init.type === 'REF') typeClass = 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30';
      typeBadge.className = `px-2.5 py-0.5 rounded-full text-[10px] font-bold ${typeClass}`;

      // Status Badge
      const statusBadge = document.getElementById('modal-status-badge');
      statusBadge.textContent = init.status === 'ACTIVE' ? 'ACTIVA' : 'ARCHIVADA';
      statusBadge.className = `px-2.5 py-0.5 rounded-full text-[10px] font-medium ${init.status === 'ACTIVE' ? 'bg-emerald-950/60 text-emerald-400 border border-emerald-800/40' : 'bg-slate-800 text-slate-400'}`;

      // QA Badge
      const qaBadge = document.getElementById('modal-qa-badge');
      qaBadge.textContent = 'QA: ' + (init.qa_verdict || 'PENDING');
      qaBadge.className = `px-2.5 py-0.5 rounded-full text-[10px] font-bold ${init.qa_verdict === 'APROBADO' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' : (init.qa_verdict === 'RECHAZADO' ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30' : 'bg-amber-500/20 text-amber-400 border border-amber-500/30')}`;

      // Artifacts Grid
      const artGrid = document.getElementById('modal-artifacts-grid');
      artGrid.innerHTML = '';
      const docItem = (name, exists, desc, role) => {
        const div = document.createElement('div');
        div.className = `p-3 rounded-xl border text-xs flex flex-col justify-between transition ${exists ? 'bg-slate-950 border-sky-500/40 text-slate-200' : 'bg-slate-950/40 border-slate-800/60 text-slate-600'}`;
        div.innerHTML = `
          <div class="flex items-center justify-between">
            <span class="font-mono font-bold text-[11px] ${exists ? 'text-sky-400' : 'text-slate-600'}">${name}</span>
            <span class="text-xs">${exists ? '✅' : '⚪'}</span>
          </div>
          <span class="text-[10px] mt-1.5 text-slate-400 leading-tight">${desc}</span>
          <span class="text-[9px] mt-2 font-mono ${exists ? 'text-emerald-400 font-semibold' : 'text-slate-600'}">Responsable: ${role}</span>
        `;
        artGrid.appendChild(div);
      };

      if (init.type === 'BUG') {
        docItem('bug-report.md', init.has_bug || init.has_spec, 'Reporte y causa raíz', 'QA / Analyst');
        docItem('qa.md', init.has_qa, 'Plan de pruebas y validación', 'QA Engineer');
        docItem('architecture.md', init.has_arch, 'Ajuste estructural (opcional)', 'Software Architect');
      } else {
        docItem('spec.md', init.has_spec, 'Especificación funcional', 'Product Analyst');
        docItem('ui-design.md', init.has_ui, 'Diseño de interfaz y UX', 'UI Designer');
        docItem('architecture.md', init.has_arch, 'Diseño técnico y ADRs', 'Software Architect');
        docItem('qa.md', init.has_qa, 'Plan y reporte de pruebas', 'QA Engineer');
        docItem('decision.md', init.has_decision, 'Registro de decisión técnica', 'Tech Lead');
      }

      // Telemetry
      const execs = (init.metrics && init.metrics.executions) ? init.metrics.executions : [];
      if (execs.length === 0) {
        document.getElementById('modal-telemetry-empty').classList.remove('hidden');
        document.getElementById('modal-telemetry-content').classList.add('hidden');
      } else {
        document.getElementById('modal-telemetry-empty').classList.add('hidden');
        document.getElementById('modal-telemetry-content').classList.remove('hidden');
        
        let initDurationSec = 0;
        let hasMeasuredDur = false;
        execs.forEach(ex => {
          if (ex.duration_s !== null && ex.duration_s !== undefined && ex.duration_s !== '' && !isNaN(Number(ex.duration_s)) && Number(ex.duration_s) > 0) {
            initDurationSec += Number(ex.duration_s);
            hasMeasuredDur = true;
          }
        });
        const durFormatted = hasMeasuredDur ? (initDurationSec >= 60 ? `${Math.round(initDurationSec / 60)} min` : `${initDurationSec}s`) : '—';

        document.getElementById('modal-tokens-total').textContent = init.metrics.hasMeasuredTokens ? (init.metrics.totalTokens || 0).toLocaleString() : '—';
        document.getElementById('modal-phases-count').textContent = init.metrics.count || 0;
        document.getElementById('modal-duration-total').textContent = durFormatted;

        const tbody = document.getElementById('modal-executions-tbody');
        tbody.innerHTML = '';
        execs.forEach(ex => {
          const tr = document.createElement('tr');
          const hasTokIn = ex.tokens_in !== null && ex.tokens_in !== undefined && ex.tokens_in !== '' && !isNaN(Number(ex.tokens_in));
          const hasTokOut = ex.tokens_out !== null && ex.tokens_out !== undefined && ex.tokens_out !== '' && !isNaN(Number(ex.tokens_out));
          const hasDur = ex.duration_s !== null && ex.duration_s !== undefined && ex.duration_s !== '' && !isNaN(Number(ex.duration_s)) && Number(ex.duration_s) > 0;

          const tokIn = hasTokIn ? Number(ex.tokens_in) : 0;
          const tokOut = hasTokOut ? Number(ex.tokens_out) : 0;
          const tokensCell = (hasTokIn || hasTokOut) && (tokIn > 0 || tokOut > 0)
            ? `${tokIn.toLocaleString()} in / ${tokOut.toLocaleString()} out`
            : '<span class="text-slate-500">—</span>';
          const durCell = hasDur ? `${Number(ex.duration_s)}s` : '<span class="text-slate-500">—</span>';
          const tsFormatted = formatTimestamp(ex.ts);
          tr.className = 'hover:bg-slate-900/80 transition';
          tr.innerHTML = `
            <td class="p-2.5 text-slate-300 font-semibold">${ex.role || '-'}<span class="block text-[9px] text-slate-500 font-normal">${ex.phase || '-'} · ${tsFormatted}</span></td>
            <td class="p-2.5 text-slate-400">${tokensCell}</td>
            <td class="p-2.5 text-slate-400">${durCell}</td>
            <td class="p-2.5"><span class="px-2 py-0.5 rounded text-[9px] font-bold ${ex.verdict === 'APROBADO' ? 'bg-emerald-500/20 text-emerald-400' : (ex.verdict === 'RECHAZADO' ? 'bg-rose-500/20 text-rose-400' : 'bg-slate-800 text-slate-400')}">${ex.verdict || '-'}</span></td>
          `;
          tbody.appendChild(tr);
        });
      }

      switchModalTab('artifacts');
      document.getElementById('initiative-modal').classList.remove('hidden');
    }

    function closeInitiativeModal() {
      document.getElementById('initiative-modal').classList.add('hidden');
    }

    function copyCurrentInitiativeId() {
      const id = document.getElementById('modal-title').textContent.trim();
      copyToClipboard(id, `ID ${id} copiado`);
    }

    function copyModalFolderPath() {
      const path = document.getElementById('modal-folder-path-display').textContent.trim();
      copyToClipboard(path, `Ruta ${path} copiada`);
    }

    function openAboutModal() {
      document.getElementById('about-modal').classList.remove('hidden');
    }

    function closeAboutModal() {
      document.getElementById('about-modal').classList.add('hidden');
    }

    // Keyboard Shortcuts for Modals
    document.addEventListener('keydown', (e) => {
      const initModal = document.getElementById('initiative-modal');
      const aboutModal = document.getElementById('about-modal');

      if (aboutModal && !aboutModal.classList.contains('hidden')) {
        if (e.key === 'Escape') closeAboutModal();
        return;
      }

      if (initModal && !initModal.classList.contains('hidden')) {
        if (e.key === 'Escape') closeInitiativeModal();
        if (e.key === 'ArrowLeft') navigateModal(-1);
        if (e.key === 'ArrowRight') navigateModal(1);
      }
    });

    // Close on backdrop click
    document.getElementById('initiative-modal').addEventListener('click', (e) => {
      if (e.target.id === 'initiative-modal') closeInitiativeModal();
    });

    document.getElementById('about-modal').addEventListener('click', (e) => {
      if (e.target.id === 'about-modal') closeAboutModal();
    });

    window.addEventListener('DOMContentLoaded', () => {
      initProject();
      initInitiatives();
      // El grafo se inicializa diferido (lazy) en switchTab('graph') para garantizar dimensiones válidas del canvas
      initDocsAndMemory();
      initMetrics();

      // Live Reload / Live Server detection
      if (window.location.protocol.startsWith('http')) {
        const dot = document.getElementById('live-indicator-dot');
        const text = document.getElementById('live-indicator-text');
        if (dot) {
          dot.className = 'inline-block w-2 h-2 rounded-full bg-emerald-400 animate-pulse';
        }
        if (text) {
          text.textContent = 'Live';
          text.className = 'hidden sm:inline text-[11px] font-bold text-emerald-400';
        }
        let currentVer = null;
        setInterval(async () => {
          try {
            const res = await fetch('/__version__?t=' + Date.now(), { cache: 'no-store' });
            if (res.ok) {
              const ver = await res.text();
              if (currentVer !== null && ver && ver !== currentVer) {
                console.log('[Abbia Live] Actualización detectada, recargando página...');
                window.location.reload();
              }
              currentVer = ver;
            }
          } catch (e) {}
        }, 1000);
      }
    });
  </script>
</body>
</html>
HTML_BODY

echo -e "${GREEN}✓ Dashboard interactivo generado en:${NC} $OUTPUT_HTML"

# Iniciar Watcher o Servidor Local si se especificó
if [ "$SERVE_MODE" -eq 1 ] || [ "$WATCH_MODE" -eq 1 ]; then
    MODE_STR="serve"
    [ "$WATCH_MODE" -eq 1 ] && [ "$SERVE_MODE" -eq 0 ] && MODE_STR="watch"

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$AI_DIR" "$PROJECT_ROOT" "$PORT" "$MODE_STR" "$SCRIPT_DIR/dashboard.sh" "$NO_OPEN" << 'PYEOF'
import sys, os, time, threading, subprocess, socketserver, http.server

abbia_dir = sys.argv[1]
project_root = sys.argv[2]
port = int(sys.argv[3])
mode = sys.argv[4] # "serve" or "watch"
script_path = sys.argv[5]
no_open = (sys.argv[6] == "1")

IGNORED_DIRS = {'.git', 'sessions', '__pycache__', 'node_modules'}
IGNORED_FILES = {'dashboard.html', 'aggregates.yaml'}

def get_latest_mtime():
    max_mtime = 0
    for root, dirs, files in os.walk(abbia_dir):
        dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]
        for f in files:
            if f in IGNORED_FILES or f.endswith('.tmp') or f.endswith('.bak'):
                continue
            try:
                p = os.path.join(root, f)
                mt = os.path.getmtime(p)
                if mt > max_mtime:
                    max_mtime = mt
            except Exception:
                pass
    return max_mtime

version_state = {"version": str(int(time.time() * 1000))}
lock = threading.Lock()

def regenerate():
    try:
        subprocess.run(["bash", script_path, "--no-open"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        with lock:
            version_state["version"] = str(int(time.time() * 1000))
        now_str = time.strftime("%H:%M:%S")
        print(f"\033[0;32m[{now_str}] 🔄 Cambios detectados en .abbia/ -> dashboard.html regenerado.\033[0m", flush=True)
    except Exception:
        pass

def watcher_loop():
    last_m = get_latest_mtime()
    while True:
        time.sleep(1.0)
        try:
            cur_m = get_latest_mtime()
            if cur_m > last_m:
                last_m = cur_m
                regenerate()
        except Exception:
            pass

w_thread = threading.Thread(target=watcher_loop, daemon=True)
w_thread.start()

if mode == "watch":
    print("\033[0;36m====================================================\033[0m")
    print("\033[0;36m   👁️  Abbia Dashboard Watcher Activo (.abbia/)     \033[0m")
    print("\033[0;36m====================================================\033[0m")
    print(f"Vigilando cambios en: \033[1;33m{abbia_dir}\033[0m")
    print("Presiona \033[1;33mCtrl+C\033[0m para detener el watcher.\n")
    if not no_open:
        dash_html = os.path.join(abbia_dir, "dashboard.html")
        if sys.platform == "darwin":
            subprocess.run(["open", dash_html])
        elif sys.platform.startswith("linux"):
            subprocess.run(["xdg-open", dash_html])
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n\033[0;33mWatcher detenido.\033[0m")
        sys.exit(0)

elif mode == "serve":
    class AbbiaHandler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=abbia_dir, **kwargs)

        def do_GET(self):
            if self.path.startswith("/__version__"):
                self.send_response(200)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                with lock:
                    ver_bytes = version_state["version"].encode("utf-8")
                self.wfile.write(ver_bytes)
                return
            if self.path == "/" or self.path == "":
                self.path = "/dashboard.html"
            return super().do_GET()

        def log_message(self, format, *args):
            if args and len(args) > 0 and "/__version__" in str(args[0]):
                return

    target_port = port
    server = None
    for p in range(target_port, target_port + 20):
        try:
            socketserver.TCPServer.allow_reuse_address = True
            server = socketserver.TCPServer(("", p), AbbiaHandler)
            target_port = p
            break
        except OSError:
            continue

    if not server:
        print(f"\033[0;31mError: No se pudo abrir el servidor en los puertos {port}-{port+20}\033[0m")
        sys.exit(1)

    url = f"http://localhost:{target_port}/dashboard.html"
    print("\033[0;36m====================================================\033[0m")
    print(f"\033[0;36m   ⚡ Abbia Live Dashboard Server (Abbia OS v4.0.0) \033[0m")
    print("\033[0;36m====================================================\033[0m")
    print(f"🚀 Dashboard disponible en: \033[1;32m{url}\033[0m")
    print(f"👁️  Live Reload:            \033[1;33mActivo (auto-recarga al guardar)\033[0m")
    print(f"📁 Directorio observado:     \033[0;34m{abbia_dir}\033[0m")
    print("\nPresiona \033[1;33mCtrl+C\033[0m para detener el servidor.\n")

    if not no_open:
        if sys.platform == "darwin":
            subprocess.run(["open", url])
        elif sys.platform.startswith("linux"):
            subprocess.run(["xdg-open", url])

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\033[0;33mServidor detenido.\033[0m")
        server.server_close()
        sys.exit(0)
PYEOF
    else
        echo -e "${RED}Error: Se requiere python3 para usar --watch o --serve.${NC}"
        exit 1
    fi
else
    # Abrir en el navegador por defecto según sistema operativo si no se pasó --no-open
    if [ "$NO_OPEN" -eq 0 ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "$OUTPUT_HTML"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v xdg-open > /dev/null; then
                xdg-open "$OUTPUT_HTML"
            fi
        fi
        echo -e "${GREEN}🚀 Dashboard abierto en tu navegador.${NC}"
    else
        echo -e "${BLUE}ℹ️  Modo --no-open activado: El dashboard no se abrió automáticamente.${NC}"
    fi
fi

