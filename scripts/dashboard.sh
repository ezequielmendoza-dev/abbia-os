#!/usr/bin/env bash

# ==============================================================================
# dashboard.sh — ai-agents Interactive Dashboard & Visualizer
# ==============================================================================
# Genera y abre un dashboard visual interactivo en el navegador para explorar:
#   1. Knowledge Graph (Grafo de decisiones arquitectónicas y dependencias)
#   2. Telemetría y Métricas (Tokens consumidos por rol, tiempos y costos)
#   3. Workflow Memory (Línea de tiempo de sesiones, catálogo y lecciones)
#   4. Catálogo Completo de Iniciativas (.ai/features/ y .ai/archive/)
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

NO_OPEN=0
for arg in "$@"; do
    case "$arg" in
        --no-open)
            NO_OPEN=1
            ;;
        -h|--help)
            echo "Uso: bash dashboard.sh [--no-open]"
            echo "Genera y abre el dashboard visual interactivo (.ai/dashboard.html)"
            exit 0
            ;;
    esac
done

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   📊 Visualizador Interactivo (ai-agents OS)       ${NC}"
echo -e "${BLUE}====================================================${NC}"
echo -e "Raíz del proyecto: ${YELLOW}$PROJECT_ROOT${NC}\n"

AI_DIR="$PROJECT_ROOT/.ai"
if [ ! -d "$AI_DIR" ]; then
    echo -e "${RED}Error: No se encontró la carpeta .ai/ en $PROJECT_ROOT${NC}"
    exit 1
fi

KG_FILE="$AI_DIR/knowledge-graph.yaml"
METRICS_FILE="$AI_DIR/metrics/executions.yaml"
MEM_DIR="$AI_DIR/memory"
LOG_FILE="$MEM_DIR/workflow-log.md"
CATALOG_FILE="$MEM_DIR/decisions-catalog.md"
PATTERNS_FILE="$MEM_DIR/patterns-learned.md"
SNAPSHOT_FILE="$MEM_DIR/context-snapshot.md"
CONTEXT_FILE="$AI_DIR/context.md"
FEATURES_DIR="$AI_DIR/features"
ARCHIVE_DIR="$AI_DIR/archive"

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

# Escanear iniciativas en .ai/features/ y .ai/archive/
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
                title=$(grep -E '^# ' "$dir/spec.md" | head -1 | sed 's/^# //' | tr -d '"\r\n\\' | sed 's/^[ \t]*//;s/[ \t]*$//' || true)
            elif [ -f "$dir/bug-report.md" ]; then
                title=$(grep -E '^# ' "$dir/bug-report.md" | head -1 | sed 's/^# //' | tr -d '"\r\n\\' | sed 's/^[ \t]*//;s/[ \t]*$//' || true)
            elif [ -f "$dir/README.md" ]; then
                title=$(grep -E '^# ' "$dir/README.md" | head -1 | sed 's/^# //' | tr -d '"\r\n\\' | sed 's/^[ \t]*//;s/[ \t]*$//' || true)
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

# Extraer datos
KG_RAW=$(read_file_or_default "$KG_FILE" "version: 1\nnodes: []\nedges: []")
METRICS_RAW=$(read_file_or_default "$METRICS_FILE" "executions: []")
LOG_RAW=$(read_file_or_default "$LOG_FILE" "(sin entradas en workflow-log.md)")
CATALOG_RAW=$(read_file_or_default "$CATALOG_FILE" "(sin catálogo)")
PATTERNS_RAW=$(read_file_or_default "$PATTERNS_FILE" "(sin patrones aprendidos)")
SNAPSHOT_RAW=$(read_file_or_default "$SNAPSHOT_FILE" "(sin snapshot)")
CONTEXT_RAW=$(read_file_or_default "$CONTEXT_FILE" "(sin context.md)")
INITIATIVES_RAW=$(scan_initiatives_json "$FEATURES_DIR" "$ARCHIVE_DIR")

OUTPUT_HTML="$AI_DIR/dashboard.html"

# Generar archivo HTML interactivo autónomo
cat << 'HTML_HEADER' > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="es" class="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ai-agents OS — Visualizador Interactivo</title>
  <script src="https://cdn.tailwindcss.com"></script>
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
    #network-canvas { width: 100%; height: 580px; border-radius: 0.75rem; }
    .tab-content { display: none; }
    .tab-content.active { display: block; }
    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-track { background: #0f172a; }
    ::-webkit-scrollbar-thumb { background: #334155; border-radius: 3px; }
    .filter-btn.active {
      background-color: #0284c7;
      color: #ffffff;
      border-color: #38bdf8;
    }
  </style>
</head>
<body class="bg-slate-950 text-slate-100 min-h-screen font-sans antialiased">
  <!-- Navbar -->
  <header class="border-b border-slate-800 bg-slate-900/80 backdrop-blur sticky top-0 z-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <span class="text-2xl">🤖</span>
        <div>
          <h1 class="text-lg font-bold bg-gradient-to-r from-sky-400 to-indigo-400 bg-clip-text text-transparent">ai-agents OS</h1>
          <p class="text-xs text-slate-400">Specification-Driven Development Visualizer</p>
        </div>
      </div>
      <nav class="flex space-x-1 bg-slate-800/60 p-1 rounded-xl border border-slate-700/50">
        <button onclick="switchTab('graph')" id="tab-btn-graph" class="tab-btn px-4 py-1.5 text-xs font-semibold rounded-lg transition-all bg-sky-500 text-white shadow-lg shadow-sky-500/20">🕸️ Knowledge Graph</button>
        <button onclick="switchTab('metrics')" id="tab-btn-metrics" class="tab-btn px-4 py-1.5 text-xs font-semibold rounded-lg transition-all text-slate-400 hover:text-slate-200">📊 Telemetría & Tokens</button>
        <button onclick="switchTab('memory')" id="tab-btn-memory" class="tab-btn px-4 py-1.5 text-xs font-semibold rounded-lg transition-all text-slate-400 hover:text-slate-200">🧠 Workflow Memory</button>
        <button onclick="switchTab('features')" id="tab-btn-features" class="tab-btn px-4 py-1.5 text-xs font-semibold rounded-lg transition-all text-slate-400 hover:text-slate-200">🚀 Iniciativas</button>
      </nav>
    </div>
  </header>

  <!-- Main Container -->
  <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
HTML_HEADER

# Inyectar datos en el HTML como scripts JSON seguros
cat << HTML_DATA >> "$OUTPUT_HTML"
  <!-- Raw Data Payload -->
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
  <script type="application/json" id="raw-initiatives">
$INITIATIVES_RAW
  </script>
HTML_DATA

cat << 'HTML_BODY' >> "$OUTPUT_HTML"
    <!-- ==================== TAB 1: KNOWLEDGE GRAPH ==================== -->
    <section id="tab-graph" class="tab-content active space-y-4">
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 bg-slate-900/60 p-4 rounded-xl border border-slate-800">
        <div>
          <h2 class="text-base font-semibold text-slate-200 flex items-center gap-2">
            <span>🕸️</span> Grafo Interactivo de Decisiones Arquitectónicas (ADRs)
          </h2>
          <p class="text-xs text-slate-400 mt-0.5">Explora dependencias, reemplazos y conflictos entre decisiones técnicas.</p>
        </div>
        <div class="flex items-center gap-3 w-full sm:w-auto">
          <input type="text" id="graph-search" oninput="filterGraph(this.value)" placeholder="Buscar ADR o título..." class="bg-slate-950 border border-slate-700 rounded-lg px-3 py-1.5 text-xs text-slate-200 focus:outline-none focus:border-sky-500 w-full sm:w-60">
          <button onclick="resetGraphView()" class="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-xs text-slate-300 font-medium rounded-lg border border-slate-700 transition">Centrar</button>
        </div>
      </div>

      <!-- Graph Container & Node Details Pane -->
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <div class="lg:col-span-3 bg-slate-900 border border-slate-800 rounded-xl relative overflow-hidden shadow-inner">
          <div id="network-canvas"></div>
          <!-- Legend Overlay -->
          <div class="absolute bottom-3 left-3 bg-slate-950/90 border border-slate-800 p-2.5 rounded-lg text-xs space-y-1.5 backdrop-blur">
            <div class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Leyenda</div>
            <div class="flex items-center gap-2"><span class="w-3 h-3 rounded-full bg-emerald-500 inline-block"></span> <span>Activo (ACTIVE)</span></div>
            <div class="flex items-center gap-2"><span class="w-3 h-3 rounded-full bg-amber-500 inline-block"></span> <span>Propuesta (PENDING)</span></div>
            <div class="flex items-center gap-2"><span class="w-3 h-3 rounded-full bg-slate-500 inline-block"></span> <span>Reemplazado (SUPERSEDED)</span></div>
            <div class="flex items-center gap-2"><span class="w-3 h-0.5 bg-sky-400 inline-block"></span> <span>depends_on</span></div>
            <div class="flex items-center gap-2"><span class="w-3 h-0.5 bg-rose-400 inline-block"></span> <span>conflicts_with</span></div>
          </div>
        </div>

        <!-- Node Detail Side Panel -->
        <div class="bg-slate-900 border border-slate-800 rounded-xl p-5 flex flex-col justify-between">
          <div id="node-detail-empty" class="text-center py-20 text-slate-500">
            <span class="text-3xl">👈</span>
            <p class="mt-2 text-xs">Haz clic en cualquier nodo del grafo para ver el detalle de la decisión arquitectónica.</p>
          </div>
          <div id="node-detail-card" class="hidden space-y-4">
            <div class="flex items-center justify-between">
              <span id="detail-id" class="font-mono text-sm font-bold text-sky-400">ARCH-001</span>
              <span id="detail-status" class="px-2 py-0.5 rounded text-[10px] font-semibold">ACTIVE</span>
            </div>
            <div>
              <h3 id="detail-title" class="text-sm font-bold text-slate-100">Título de la Decisión</h3>
            </div>
            <div class="border-t border-slate-800 pt-3 space-y-2 text-xs">
              <div>
                <span class="text-slate-400 block font-medium">Depende de:</span>
                <span id="detail-depends" class="font-mono text-slate-300">-</span>
              </div>
              <div>
                <span class="text-slate-400 block font-medium">Reemplaza a:</span>
                <span id="detail-supersedes" class="font-mono text-slate-300">-</span>
              </div>
              <div>
                <span class="text-slate-400 block font-medium">Conflictos potenciales:</span>
                <span id="detail-conflicts" class="font-mono text-rose-400">-</span>
              </div>
            </div>
          </div>
          <div class="mt-4 pt-3 border-t border-slate-800 text-[11px] text-slate-500">
            Fuente de verdad: <code class="text-slate-400">.ai/decisions.md</code>
          </div>
        </div>
      </div>
    </section>

    <!-- ==================== TAB 2: TELEMETRÍA & TOKENS ==================== -->
    <section id="tab-metrics" class="tab-content space-y-6">
      <!-- KPI Cards -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div class="bg-slate-900 border border-slate-800 p-4 rounded-xl">
          <div class="text-xs text-slate-400 font-medium">Tokens Totales</div>
          <div id="kpi-tokens-total" class="text-2xl font-black text-sky-400 mt-1">0</div>
          <div class="text-[10px] text-slate-500 mt-1"><span id="kpi-tokens-in">0</span> in · <span id="kpi-tokens-out">0</span> out</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-4 rounded-xl flex flex-col justify-between">
          <div class="flex items-center justify-between gap-1">
            <div class="text-xs text-slate-400 font-medium">Costo Estimado</div>
            <select id="pricing-model-select" onchange="updateSelectedPricingModel(this.value)" class="bg-slate-950 border border-slate-700 text-[10px] text-sky-400 font-mono rounded px-1.5 py-0.5 focus:outline-none focus:border-sky-500">
              <option value="sonnet" selected>Sonnet 3.5 / GPT-4o</option>
              <option value="haiku">Haiku 3.5 / Mini</option>
              <option value="gemini-flash">Gemini 1.5 Flash</option>
              <option value="gemini-pro">Gemini 1.5 Pro</option>
              <option value="opus">Opus 3</option>
            </select>
          </div>
          <div id="kpi-cost" class="text-2xl font-black text-emerald-400 mt-1">$0.00 USD</div>
          <div class="text-[10px] text-slate-500 mt-1" id="kpi-cost-breakdown">In: $0.00 · Out: $0.00</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-4 rounded-xl">
          <div class="text-xs text-slate-400 font-medium">Sesiones de Agente</div>
          <div id="kpi-sessions" class="text-2xl font-black text-indigo-400 mt-1">0</div>
          <div class="text-[10px] text-slate-500 mt-1"><span id="kpi-retries">0</span> reintentos de gate</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-4 rounded-xl">
          <div class="text-xs text-slate-400 font-medium">Tiempo de Pipeline</div>
          <div id="kpi-time" class="text-2xl font-black text-amber-400 mt-1">0m</div>
          <div class="text-[10px] text-slate-500 mt-1">Duración acumulada de fases</div>
        </div>
      </div>

      <!-- Charts Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-slate-900 border border-slate-800 p-5 rounded-xl">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center justify-between">
            <span>Consumo de Tokens por Rol</span>
            <span class="text-[10px] font-normal text-slate-500">In + Out</span>
          </h3>
          <div class="h-64 flex items-center justify-center">
            <canvas id="chart-roles"></canvas>
          </div>
        </div>

        <div class="bg-slate-900 border border-slate-800 p-5 rounded-xl">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center justify-between">
            <span>Tokens por Fase del Pipeline</span>
            <span class="text-[10px] font-normal text-slate-500">Distribución</span>
          </h3>
          <div class="h-64 flex items-center justify-center">
            <canvas id="chart-phases"></canvas>
          </div>
        </div>
      </div>

      <!-- Executions History Table -->
      <div class="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <div class="p-4 border-b border-slate-800 flex items-center justify-between">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider">Historial de Ejecuciones de Agentes</h3>
          <span id="table-count" class="text-xs text-slate-500">0 ejecuciones</span>
        </div>
        <div class="overflow-x-auto max-h-96 overflow-y-auto">
          <table class="w-full text-left text-xs">
            <thead class="bg-slate-950/80 text-slate-400 uppercase text-[10px] tracking-wider sticky top-0">
              <tr>
                <th class="py-2.5 px-4 font-semibold">Timestamp</th>
                <th class="py-2.5 px-4 font-semibold">Iniciativa</th>
                <th class="py-2.5 px-4 font-semibold">Rol</th>
                <th class="py-2.5 px-4 font-semibold">Fase</th>
                <th class="py-2.5 px-4 font-semibold">Tokens In</th>
                <th class="py-2.5 px-4 font-semibold">Tokens Out</th>
                <th class="py-2.5 px-4 font-semibold">Duración</th>
                <th class="py-2.5 px-4 font-semibold">Veredicto</th>
              </tr>
            </thead>
            <tbody id="executions-tbody" class="divide-y divide-slate-800/60 font-mono text-[11px]">
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <!-- ==================== TAB 3: WORKFLOW MEMORY ==================== -->
    <section id="tab-memory" class="tab-content space-y-6">
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Context Snapshot -->
        <div class="lg:col-span-2 space-y-6">
          <div class="bg-slate-900 border border-slate-800 rounded-xl p-5">
            <div class="flex items-center justify-between pb-3 border-b border-slate-800">
              <h3 class="text-xs font-bold text-sky-400 uppercase tracking-wider flex items-center gap-2">
                <span>🧠</span> Context Snapshot (Compactado para Sesión)
              </h3>
              <span class="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded">context-snapshot.md</span>
            </div>
            <div id="snapshot-content" class="prose prose-invert prose-sm text-xs mt-4 max-h-96 overflow-y-auto pr-2"></div>
          </div>

          <!-- Workflow Log Timeline -->
          <div class="bg-slate-900 border border-slate-800 rounded-xl p-5">
            <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center gap-2">
              <span>📜</span> Línea de Tiempo de Sesiones (Episódica)
            </h3>
            <div id="log-timeline" class="space-y-4 max-h-[500px] overflow-y-auto pr-2"></div>
          </div>
        </div>

        <!-- Decisions Catalog & Patterns -->
        <div class="space-y-6">
          <div class="bg-slate-900 border border-slate-800 rounded-xl p-5">
            <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3 flex items-center justify-between">
              <span>⚖️ Catálogo de Decisiones</span>
              <span class="text-[10px] text-slate-500 font-normal">Semántica</span>
            </h3>
            <div id="catalog-content" class="prose prose-invert prose-xs text-xs max-h-60 overflow-y-auto"></div>
          </div>

          <div class="bg-slate-900 border border-slate-800 rounded-xl p-5">
            <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3 flex items-center justify-between">
              <span>💡 Patrones Aprendidos</span>
              <span class="text-[10px] text-slate-500 font-normal">Procedimental</span>
            </h3>
            <div id="patterns-content" class="prose prose-invert prose-xs text-xs max-h-60 overflow-y-auto"></div>
          </div>
        </div>
      </div>
    </section>

    <!-- ==================== TAB 4: INICIATIVAS COMPLETAS ==================== -->
    <section id="tab-features" class="tab-content space-y-6">
      <!-- Quick Summary Cards -->
      <div class="grid grid-cols-2 sm:grid-cols-6 gap-3">
        <div class="bg-slate-900 border border-slate-800 p-3.5 rounded-xl">
          <div class="text-[11px] text-slate-400 font-medium">Iniciativas Totales</div>
          <div id="init-kpi-total" class="text-xl font-black text-sky-400 mt-1">0</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-3.5 rounded-xl">
          <div class="text-[11px] text-slate-400 font-medium">Activas (.ai/features)</div>
          <div id="init-kpi-active" class="text-xl font-black text-emerald-400 mt-1">0</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-3.5 rounded-xl">
          <div class="text-[11px] text-slate-400 font-medium">Archivadas (.ai/archive)</div>
          <div id="init-kpi-archived" class="text-xl font-black text-slate-400 mt-1">0</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-3.5 rounded-xl">
          <div class="text-[11px] text-slate-400 font-medium">Features (FEAT)</div>
          <div id="init-kpi-feats" class="text-xl font-black text-sky-300 mt-1">0</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-3.5 rounded-xl">
          <div class="text-[11px] text-slate-400 font-medium">Bugs (BUG)</div>
          <div id="init-kpi-bugs" class="text-xl font-black text-rose-400 mt-1">0</div>
        </div>
        <div class="bg-slate-900 border border-slate-800 p-3.5 rounded-xl">
          <div class="text-[11px] text-slate-400 font-medium">QA Aprobado</div>
          <div id="init-kpi-approved" class="text-xl font-black text-teal-400 mt-1">0</div>
        </div>
      </div>

      <!-- Advanced Filter & Search Toolbar -->
      <div class="bg-slate-900/80 p-4 rounded-xl border border-slate-800 space-y-3">
        <div class="flex flex-col md:flex-row items-center justify-between gap-3">
          <!-- Live Text Search -->
          <div class="relative w-full md:w-96">
            <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-500 text-xs">🔍</span>
            <input type="text" id="init-search-input" oninput="applyInitiativeFilters()" placeholder="Buscar por ID, título o palabra clave..." class="w-full bg-slate-950 border border-slate-700 rounded-lg pl-8 pr-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-sky-500 placeholder:text-slate-600">
          </div>

          <!-- Sort Selector -->
          <div class="flex items-center gap-2 w-full md:w-auto justify-end">
            <span class="text-xs text-slate-400">Ordenar:</span>
            <select id="init-sort-select" onchange="applyInitiativeFilters()" class="bg-slate-950 border border-slate-700 text-xs text-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-sky-500">
              <option value="id-asc">ID (A - Z)</option>
              <option value="id-desc">ID (Z - A)</option>
              <option value="tokens-desc">Más tokens invertidos</option>
              <option value="tokens-asc">Menos tokens invertidos</option>
              <option value="title-asc">Título (A - Z)</option>
            </select>
          </div>
        </div>

        <!-- Filter Pill Buttons -->
        <div class="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-slate-800/80 text-xs">
          <!-- Type Filter -->
          <div class="flex items-center gap-1.5 flex-wrap">
            <span class="text-[11px] font-semibold text-slate-400 mr-1">Tipo:</span>
            <button onclick="setTypeFilter('ALL')" id="filter-type-ALL" class="filter-type-btn filter-btn active px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">Todos</button>
            <button onclick="setTypeFilter('FEAT')" id="filter-type-FEAT" class="filter-type-btn filter-btn px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">FEAT</button>
            <button onclick="setTypeFilter('BUG')" id="filter-type-BUG" class="filter-type-btn filter-btn px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">BUG</button>
            <button onclick="setTypeFilter('AUDIT')" id="filter-type-AUDIT" class="filter-type-btn filter-btn px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">AUDIT</button>
            <button onclick="setTypeFilter('REF')" id="filter-type-REF" class="filter-type-btn filter-btn px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">REF</button>
          </div>

          <!-- Status Filter -->
          <div class="flex items-center gap-1.5 flex-wrap">
            <span class="text-[11px] font-semibold text-slate-400 mr-1">Estado:</span>
            <button onclick="setStatusFilter('ALL')" id="filter-status-ALL" class="filter-status-btn filter-btn active px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">Todas</button>
            <button onclick="setStatusFilter('ACTIVE')" id="filter-status-ACTIVE" class="filter-status-btn filter-btn px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">Activas</button>
            <button onclick="setStatusFilter('ARCHIVED')" id="filter-status-ARCHIVED" class="filter-status-btn filter-btn px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">Archivadas</button>
          </div>

          <!-- QA Status Filter -->
          <div class="flex items-center gap-1.5 flex-wrap">
            <span class="text-[11px] font-semibold text-slate-400 mr-1">QA:</span>
            <button onclick="setQaFilter('ALL')" id="filter-qa-ALL" class="filter-qa-btn filter-btn active px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">Todos</button>
            <button onclick="setQaFilter('APROBADO')" id="filter-qa-APROBADO" class="filter-qa-btn filter-btn px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">🟢 Aprobado</button>
            <button onclick="setQaFilter('PENDING')" id="filter-qa-PENDING" class="filter-qa-btn filter-btn px-2.5 py-1 rounded-md text-[11px] border border-slate-700 bg-slate-800 text-slate-300 hover:bg-slate-700">🟡 Pendiente / En Curso</button>
          </div>
        </div>
      </div>

      <!-- Counter feedback -->
      <div class="flex items-center justify-between text-xs text-slate-400 px-1">
        <span id="initiatives-count-label">Mostrando 0 iniciativas</span>
      </div>

      <!-- Initiatives Responsive Cards Grid -->
      <div id="initiatives-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"></div>
    </section>
  </main>

  <!-- Initiative Detail Modal Dialog -->
  <div id="initiative-modal" class="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 hidden flex items-center justify-center p-4">
    <div class="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full max-h-[85vh] flex flex-col shadow-2xl overflow-hidden">
      <!-- Modal Header -->
      <div class="p-5 border-b border-slate-800 flex items-start justify-between bg-slate-900/90">
        <div>
          <div class="flex items-center gap-2">
            <span id="modal-type-badge" class="px-2 py-0.5 rounded text-[10px] font-bold">FEAT</span>
            <span id="modal-status-badge" class="px-2 py-0.5 rounded text-[10px] font-medium bg-slate-800 text-slate-300">ACTIVA</span>
            <span id="modal-qa-badge" class="px-2 py-0.5 rounded text-[10px] font-bold">QA: PENDING</span>
          </div>
          <h3 id="modal-title" class="text-base font-bold text-slate-100 mt-2 font-mono">FEAT-001</h3>
          <p id="modal-desc" class="text-xs text-slate-400 mt-0.5"></p>
        </div>
        <button onclick="closeInitiativeModal()" class="text-slate-400 hover:text-slate-200 text-xl font-bold p-1 rounded-lg hover:bg-slate-800 transition">✕</button>
      </div>

      <!-- Modal Body -->
      <div class="p-5 overflow-y-auto space-y-5 text-xs">
        <!-- Artifacts Checklist -->
        <div>
          <h4 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">📄 Artefactos de la Metodología (SDD)</h4>
          <div id="modal-artifacts-grid" class="grid grid-cols-2 sm:grid-cols-3 gap-2"></div>
        </div>

        <!-- Telemetry for this initiative -->
        <div>
          <h4 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">⚡ Telemetría e Inversión de Tokens</h4>
          <div id="modal-telemetry-empty" class="text-slate-500 text-xs italic">No hay ejecuciones registradas en executions.yaml para esta iniciativa.</div>
          <div id="modal-telemetry-content" class="hidden space-y-2">
            <div class="grid grid-cols-3 gap-2 text-center bg-slate-950 p-3 rounded-lg border border-slate-800">
              <div>
                <div class="text-[10px] text-slate-500">Tokens Totales</div>
                <div id="modal-tokens-total" class="font-bold text-sky-400 text-sm">0</div>
              </div>
              <div>
                <div class="text-[10px] text-slate-500">Fases Registradas</div>
                <div id="modal-phases-count" class="font-bold text-indigo-400 text-sm">0</div>
              </div>
              <div>
                <div class="text-[10px] text-slate-500">Costo Est. USD</div>
                <div id="modal-cost-est" class="font-bold text-emerald-400 text-sm">$0.00</div>
              </div>
            </div>
            <div class="border border-slate-800 rounded-lg overflow-hidden mt-3">
              <table class="w-full text-left text-[11px]">
                <thead class="bg-slate-950 text-slate-400 uppercase text-[9px]">
                  <tr>
                    <th class="p-2">Rol / Fase</th>
                    <th class="p-2">Tokens</th>
                    <th class="p-2">Duración</th>
                    <th class="p-2">Veredicto</th>
                  </tr>
                </thead>
                <tbody id="modal-executions-tbody" class="divide-y divide-slate-800/60 font-mono"></tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- Modal Footer -->
      <div class="p-4 border-t border-slate-800 bg-slate-950/60 flex items-center justify-between">
        <span class="text-[11px] text-slate-500 font-mono" id="modal-folder-path">.ai/features/FEAT-001</span>
        <button onclick="closeInitiativeModal()" class="px-4 py-1.5 bg-slate-800 hover:bg-slate-700 text-xs text-slate-200 font-semibold rounded-lg border border-slate-700 transition">Cerrar</button>
      </div>
    </div>
  </div>

  <script>
    // --- Data Parsing ---
    let kgData = { nodes: [], edges: [] };
    let metricsData = { executions: [] };
    let allInitiatives = [];

    try {
      const kgRaw = document.getElementById('raw-kg').textContent.trim();
      kgData = jsyaml.load(kgRaw) || { nodes: [], edges: [] };
    } catch (e) { console.error('Error parseando KG YAML:', e); }

    try {
      const metricsRaw = document.getElementById('raw-metrics').textContent.trim();
      metricsData = jsyaml.load(metricsRaw) || { executions: [] };
    } catch (e) { console.error('Error parseando Metrics YAML:', e); }

    try {
      allInitiatives = JSON.parse(document.getElementById('raw-initiatives').textContent.trim() || '[]');
    } catch (e) { console.error('Error parseando Iniciativas JSON:', e); }

    const logRaw = document.getElementById('raw-log').textContent;
    const catalogRaw = document.getElementById('raw-catalog').textContent;
    const patternsRaw = document.getElementById('raw-patterns').textContent;
    const snapshotRaw = document.getElementById('raw-snapshot').textContent;

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

      if (tabId === 'graph' && network) {
        setTimeout(() => network.fit(), 50);
      }
    }

    // --- Graph Visualization (Vis.js) ---
    let network = null;
    let visNodes = null;
    let visEdges = null;

    function initGraph() {
      const container = document.getElementById('network-canvas');
      const nodesArray = [];
      const edgesArray = [];

      (kgData.nodes || []).forEach(node => {
        let bgColor = '#10b981'; // ACTIVE = emerald
        let borderColor = '#34d399';
        if (node.status === 'PENDING') { bgColor = '#f59e0b'; borderColor = '#fbbf24'; }
        if (node.status === 'SUPERSEDED' || node.status === 'DEPRECATED') { bgColor = '#64748b'; borderColor = '#94a3b8'; }

        nodesArray.push({
          id: node.id,
          label: `${node.id}\n${node.title || ''}`,
          color: { background: bgColor, border: borderColor, highlight: { background: '#38bdf8', border: '#7dd3fc' } },
          font: { color: '#ffffff', size: 12, face: 'monospace', multi: true, bold: { size: 13 } },
          shape: 'box',
          margin: 10,
          borderWidth: 2,
          shadow: true,
          data: node
        });

        // Relaciones inline
        (node.depends_on || []).forEach(dep => {
          edgesArray.push({ from: node.id, to: dep, arrows: 'to', label: 'depends_on', color: { color: '#38bdf8', highlight: '#7dd3fc' }, font: { size: 10, color: '#94a3b8' } });
        });
        (node.supersedes || []).forEach(sup => {
          edgesArray.push({ from: node.id, to: sup, arrows: 'to', label: 'supersedes', dashes: true, color: { color: '#f59e0b' }, font: { size: 10, color: '#fbbf24' } });
        });
        (node.conflicts_with || []).forEach(conf => {
          edgesArray.push({ from: node.id, to: conf, arrows: 'to,from', label: 'conflicts_with', dashes: true, color: { color: '#f43f5e' }, font: { size: 10, color: '#f43f5e' } });
        });
      });

      (kgData.edges || []).forEach(edge => {
        edgesArray.push({
          from: edge.from,
          to: edge.to,
          arrows: 'to',
          label: edge.type || '',
          color: { color: edge.type === 'conflicts_with' ? '#f43f5e' : '#38bdf8' }
        });
      });

      visNodes = new vis.DataSet(nodesArray);
      visEdges = new vis.DataSet(edgesArray);

      const data = { nodes: visNodes, edges: visEdges };
      const options = {
        layout: { hierarchical: false },
        physics: {
          solver: 'forceAtlas2Based',
          forceAtlas2Based: { gravitationalConstant: -50, centralGravity: 0.01, springLength: 120, springConstant: 0.08 }
        },
        interaction: { hover: true, tooltipDelay: 200 }
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
    }

    function showNodeDetails(node) {
      document.getElementById('node-detail-empty').classList.add('hidden');
      const card = document.getElementById('node-detail-card');
      card.classList.remove('hidden');

      document.getElementById('detail-id').textContent = node.id;
      document.getElementById('detail-title').textContent = node.title || '(Sin título)';
      
      const statusEl = document.getElementById('detail-status');
      statusEl.textContent = node.status || 'ACTIVE';
      statusEl.className = `px-2 py-0.5 rounded font-semibold text-[10px] ${node.status === 'PENDING' ? 'bg-amber-500/20 text-amber-400' : 'bg-emerald-500/20 text-emerald-400'}`;

      document.getElementById('detail-depends').textContent = JSON.stringify(node.depends_on || []);
      document.getElementById('detail-supersedes').textContent = JSON.stringify(node.supersedes || []);
      document.getElementById('detail-conflicts').textContent = JSON.stringify(node.conflicts_with || []);
    }

    function filterGraph(query) {
      if (!visNodes) return;
      const lower = query.toLowerCase();
      const allNodes = visNodes.get();
      allNodes.forEach(node => {
        const matches = node.id.toLowerCase().includes(lower) || (node.data.title && node.data.title.toLowerCase().includes(lower));
        visNodes.update({ id: node.id, hidden: !matches });
      });
    }

    function resetGraphView() {
      if (network) network.fit();
    }

    // --- Pricing Models & Currency Formatting ---
    const PRICING_MODELS = {
      'sonnet': { in: 3.00, out: 15.00, name: 'Claude 3.5 Sonnet / GPT-4o' },
      'haiku': { in: 0.25, out: 1.25, name: 'Claude 3.5 Haiku / GPT-4o-mini' },
      'gemini-flash': { in: 0.075, out: 0.30, name: 'Gemini 1.5 Flash' },
      'gemini-pro': { in: 1.25, out: 5.00, name: 'Gemini 1.5 Pro' },
      'opus': { in: 15.00, out: 75.00, name: 'Claude 3 Opus' }
    };

    let globalTotalIn = 0;
    let globalTotalOut = 0;

    function formatCurrencyUSD(val) {
      if (val === 0 || isNaN(val)) return '$0.00 USD';
      if (val < 0.01) return '< $0.01 USD';
      return '$' + val.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' USD';
    }

    function calculateCostUSD(tokensIn, tokensOut, modelKey = 'sonnet') {
      const model = PRICING_MODELS[modelKey] || PRICING_MODELS['sonnet'];
      const costIn = (tokensIn * model.in) / 1000000;
      const costOut = (tokensOut * model.out) / 1000000;
      return { costIn, costOut, total: costIn + costOut, model };
    }

    function updateSelectedPricingModel(modelKey) {
      const calc = calculateCostUSD(globalTotalIn, globalTotalOut, modelKey);
      document.getElementById('kpi-cost').textContent = formatCurrencyUSD(calc.total);
      document.getElementById('kpi-cost-breakdown').textContent = `In: $${calc.costIn.toFixed(2)} · Out: $${calc.costOut.toFixed(2)} ($${calc.model.in}/$${calc.model.out} por 1M)`;
    }

    // --- Telemetría & Charts (Chart.js) ---
    function initMetrics() {
      const executions = metricsData.executions || [];
      let totalIn = 0, totalOut = 0, totalSec = 0, retries = 0;
      const roleTokens = {};
      const phaseTokens = {};

      executions.forEach(ex => {
        const inTok = Number(ex.tokens_in) || 0;
        const outTok = Number(ex.tokens_out) || 0;
        const sum = inTok + outTok;
        totalIn += inTok;
        totalOut += outTok;
        totalSec += (Number(ex.duration_s) || 0);
        if (Number(ex.attempts) > 1) retries += (Number(ex.attempts) - 1);

        const role = ex.role || 'desconocido';
        const phase = ex.phase || 'otras';

        roleTokens[role] = (roleTokens[role] || 0) + sum;
        phaseTokens[phase] = (phaseTokens[phase] || 0) + sum;
      });

      globalTotalIn = totalIn;
      globalTotalOut = totalOut;

      const totalTokens = totalIn + totalOut;
      document.getElementById('kpi-tokens-total').textContent = totalTokens.toLocaleString();
      document.getElementById('kpi-tokens-in').textContent = totalIn.toLocaleString();
      document.getElementById('kpi-tokens-out').textContent = totalOut.toLocaleString();
      document.getElementById('kpi-sessions').textContent = executions.length;
      document.getElementById('kpi-retries').textContent = retries;
      document.getElementById('kpi-time').textContent = Math.round(totalSec / 60) + ' min';

      const initialModel = document.getElementById('pricing-model-select').value || 'sonnet';
      updateSelectedPricingModel(initialModel);

      // Render Charts
      new Chart(document.getElementById('chart-roles'), {
        type: 'doughnut',
        data: {
          labels: Object.keys(roleTokens),
          datasets: [{ data: Object.values(roleTokens), backgroundColor: ['#0ea5e9', '#6366f1', '#10b981', '#f59e0b', '#ec4899', '#8b5cf6'] }]
        },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { color: '#94a3b8', font: { size: 11 } } } } }
      });

      new Chart(document.getElementById('chart-phases'), {
        type: 'bar',
        data: {
          labels: Object.keys(phaseTokens),
          datasets: [{ label: 'Tokens Totales', data: Object.values(phaseTokens), backgroundColor: '#38bdf8', borderRadius: 6 }]
        },
        options: { responsive: true, maintainAspectRatio: false, scales: { x: { ticks: { color: '#94a3b8' } }, y: { ticks: { color: '#94a3b8' } } }, plugins: { legend: { display: false } } }
      });

      // Populate Table
      const tbody = document.getElementById('executions-tbody');
      document.getElementById('table-count').textContent = executions.length + ' ejecuciones';
      executions.slice().reverse().forEach(ex => {
        const tr = document.createElement('tr');
        tr.className = 'hover:bg-slate-800/40 transition';
        tr.innerHTML = `
          <td class="py-2.5 px-4 text-slate-400">${(ex.ts || '').replace('T', ' ').replace('Z', '')}</td>
          <td class="py-2.5 px-4 font-bold text-sky-400">${ex.initiative || '-'}</td>
          <td class="py-2.5 px-4 text-slate-300">${ex.role || '-'}</td>
          <td class="py-2.5 px-4 text-slate-400">${ex.phase || '-'}</td>
          <td class="py-2.5 px-4 text-slate-400">${(ex.tokens_in || 0).toLocaleString()}</td>
          <td class="py-2.5 px-4 text-slate-400">${(ex.tokens_out || 0).toLocaleString()}</td>
          <td class="py-2.5 px-4 text-slate-400">${ex.duration_s || 0}s</td>
          <td class="py-2.5 px-4"><span class="px-2 py-0.5 rounded text-[10px] font-bold ${ex.verdict === 'APROBADO' || ex.verdict === 'PASS' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-800 text-slate-400'}">${ex.verdict || '-'}</span></td>
        `;
        tbody.appendChild(tr);
      });
    }

    // --- Memory & Markdown Rendering ---
    function initMemory() {
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
        card.className = 'bg-slate-950/70 border border-slate-800 p-4 rounded-xl space-y-2 border-l-4 border-l-sky-500 shadow-sm';
        card.innerHTML = `
          <h4 class="text-xs font-bold text-slate-200">${header}</h4>
          <div class="prose prose-invert prose-xs text-slate-300 text-xs">${marked.parse(body)}</div>
        `;
        timelineContainer.appendChild(card);
      });
    }

    // ==================== TAB 4: INITIATIVES CONTROLLER ====================
    let currentTypeFilter = 'ALL';
    let currentStatusFilter = 'ALL';
    let currentQaFilter = 'ALL';

    function setTypeFilter(type) {
      currentTypeFilter = type;
      document.querySelectorAll('.filter-type-btn').forEach(btn => btn.classList.remove('active'));
      document.getElementById('filter-type-' + type).classList.add('active');
      applyInitiativeFilters();
    }

    function setStatusFilter(status) {
      currentStatusFilter = status;
      document.querySelectorAll('.filter-status-btn').forEach(btn => btn.classList.remove('active'));
      document.getElementById('filter-status-' + status).classList.add('active');
      applyInitiativeFilters();
    }

    function setQaFilter(qa) {
      currentQaFilter = qa;
      document.querySelectorAll('.filter-qa-btn').forEach(btn => btn.classList.remove('active'));
      document.getElementById('filter-qa-' + qa).classList.add('active');
      applyInitiativeFilters();
    }

    function initInitiatives() {
      // Cruzar métricas con iniciativas
      const initMetrics = {};
      (metricsData.executions || []).forEach(ex => {
        if (!ex.initiative) return;
        const key = ex.initiative;
        if (!initMetrics[key]) initMetrics[key] = { count: 0, tokensIn: 0, tokensOut: 0, totalTokens: 0, executions: [], lastTs: ex.ts };
        const sum = (Number(ex.tokens_in) || 0) + (Number(ex.tokens_out) || 0);
        initMetrics[key].count++;
        initMetrics[key].tokensIn += (Number(ex.tokens_in) || 0);
        initMetrics[key].tokensOut += (Number(ex.tokens_out) || 0);
        initMetrics[key].totalTokens += sum;
        initMetrics[key].executions.push(ex);
        initMetrics[key].lastTs = ex.ts;
      });

      // Asignar métricas a la lista de iniciativas
      allInitiatives.forEach(init => {
        const met = initMetrics[init.id] || { count: 0, tokensIn: 0, tokensOut: 0, totalTokens: 0, executions: [], lastTs: '-' };
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
        if (currentStatusFilter !== 'ALL' && item.status !== currentStatusFilter) return false;

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

      document.getElementById('initiatives-count-label').textContent = `Mostrando ${filtered.length} de ${allInitiatives.length} iniciativas`;

      if (filtered.length === 0) {
        grid.innerHTML = `
          <div class="col-span-full py-16 text-center text-slate-500 bg-slate-900/40 border border-slate-800 rounded-xl">
            <span class="text-3xl block">🔍</span>
            <p class="mt-2 text-xs">No se encontraron iniciativas que coincidan con los filtros seleccionados.</p>
          </div>
        `;
        return;
      }

      filtered.forEach(init => {
        const card = document.createElement('div');
        card.className = 'bg-slate-900 border border-slate-800 hover:border-slate-700 transition-all rounded-xl p-4.5 flex flex-col justify-between space-y-4 shadow-sm hover:shadow-md';

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

        // Artifact chips helper
        const chip = (label, active, icon) => `
          <span class="px-2 py-0.5 rounded text-[10px] font-mono flex items-center gap-1 ${active ? 'bg-slate-800 text-sky-300 border border-sky-500/30' : 'bg-slate-950/60 text-slate-600 border border-slate-800'}">
            <span>${icon}</span>
            <span>${label}</span>
          </span>
        `;

        card.innerHTML = `
          <div class="space-y-2.5">
            <!-- Header Badges -->
            <div class="flex items-center justify-between gap-2 flex-wrap">
              <div class="flex items-center gap-1.5">
                <span class="px-2 py-0.5 rounded text-[10px] font-bold ${typeBadgeClass}">${init.type}</span>
                <span class="px-2 py-0.5 rounded text-[10px] ${init.status === 'ACTIVE' ? 'bg-emerald-950/60 text-emerald-400 border border-emerald-800/40' : 'bg-slate-800 text-slate-400'}">${init.status === 'ACTIVE' ? 'Activa' : 'Archivada'}</span>
              </div>
              <span class="px-2 py-0.5 rounded text-[10px] font-semibold ${qaBadgeClass}">${qaText}</span>
            </div>

            <!-- ID and Title -->
            <div>
              <span class="font-mono text-xs font-bold text-sky-400 block">${init.id}</span>
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
          </div>

          <!-- Card Footer & Actions -->
          <div class="border-t border-slate-800/80 pt-3 flex items-center justify-between text-xs">
            <div class="text-[11px] text-slate-400">
              <span class="font-bold text-slate-200">${(init.metrics.totalTokens || 0).toLocaleString()}</span> tokens
              <span class="text-slate-500">(${init.metrics.count || 0} fases)</span>
            </div>
            <button onclick="openInitiativeModal('${init.id}')" class="px-3 py-1 bg-slate-800 hover:bg-sky-600 hover:text-white text-slate-300 font-medium rounded-lg text-xs transition border border-slate-700">Explorar</button>
          </div>
        `;
        grid.appendChild(card);
      });
    }

    // Modal Manager
    function openInitiativeModal(id) {
      const init = allInitiatives.find(i => i.id === id);
      if (!init) return;

      document.getElementById('modal-title').textContent = init.id;
      document.getElementById('modal-desc').textContent = init.title || '';
      document.getElementById('modal-folder-path').textContent = (init.status === 'ACTIVE' ? '.ai/features/' : '.ai/archive/') + init.id;

      // Type Badge
      const typeBadge = document.getElementById('modal-type-badge');
      typeBadge.textContent = init.type;
      typeBadge.className = `px-2 py-0.5 rounded text-[10px] font-bold ${init.type === 'BUG' ? 'bg-rose-500/20 text-rose-400' : 'bg-sky-500/20 text-sky-400'}`;

      // Status Badge
      const statusBadge = document.getElementById('modal-status-badge');
      statusBadge.textContent = init.status === 'ACTIVE' ? 'ACTIVA' : 'ARCHIVADA';
      statusBadge.className = `px-2 py-0.5 rounded text-[10px] font-medium ${init.status === 'ACTIVE' ? 'bg-emerald-950/60 text-emerald-400 border border-emerald-800/40' : 'bg-slate-800 text-slate-400'}`;

      // QA Badge
      const qaBadge = document.getElementById('modal-qa-badge');
      qaBadge.textContent = 'QA: ' + init.qa_verdict;
      qaBadge.className = `px-2 py-0.5 rounded text-[10px] font-bold ${init.qa_verdict === 'APROBADO' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-amber-500/20 text-amber-400'}`;

      // Artifacts Grid
      const artGrid = document.getElementById('modal-artifacts-grid');
      artGrid.innerHTML = '';
      const docItem = (name, exists, desc) => {
        const div = document.createElement('div');
        div.className = `p-2.5 rounded-lg border text-xs flex flex-col justify-between ${exists ? 'bg-slate-950 border-sky-500/40 text-slate-200' : 'bg-slate-950/40 border-slate-800/60 text-slate-600'}`;
        div.innerHTML = `
          <div class="flex items-center justify-between">
            <span class="font-mono font-bold text-[11px] ${exists ? 'text-sky-400' : 'text-slate-600'}">${name}</span>
            <span>${exists ? '✅' : '❌'}</span>
          </div>
          <span class="text-[10px] mt-1 text-slate-500">${desc}</span>
        `;
        artGrid.appendChild(div);
      };

      if (init.type === 'BUG') {
        docItem('bug-report.md', init.has_bug || init.has_spec, 'Reporte y causa raíz');
        docItem('qa.md', init.has_qa, 'Plan de pruebas y validación');
        docItem('architecture.md', init.has_arch, 'Ajuste estructural (opcional)');
      } else {
        docItem('spec.md', init.has_spec, 'Especificación funcional');
        docItem('ui-design.md', init.has_ui, 'Diseño de interfaz y UX');
        docItem('architecture.md', init.has_arch, 'Diseño técnico y ADRs');
        docItem('qa.md', init.has_qa, 'Plan y reporte de pruebas');
        docItem('decision.md', init.has_decision, 'Registro de decisión técnica');
      }

      // Telemetry
      const execs = (init.metrics && init.metrics.executions) ? init.metrics.executions : [];
      if (execs.length === 0) {
        document.getElementById('modal-telemetry-empty').classList.remove('hidden');
        document.getElementById('modal-telemetry-content').classList.add('hidden');
      } else {
        document.getElementById('modal-telemetry-empty').classList.add('hidden');
        document.getElementById('modal-telemetry-content').classList.remove('hidden');
        
        document.getElementById('modal-tokens-total').textContent = (init.metrics.totalTokens || 0).toLocaleString();
        const modelKey = document.getElementById('pricing-model-select') ? document.getElementById('pricing-model-select').value : 'sonnet';
        const initCost = calculateCostUSD(init.metrics.tokensIn || 0, init.metrics.tokensOut || 0, modelKey);
        document.getElementById('modal-cost-est').textContent = formatCurrencyUSD(initCost.total);

        const tbody = document.getElementById('modal-executions-tbody');
        tbody.innerHTML = '';
        execs.forEach(ex => {
          const tr = document.createElement('tr');
          const tok = (Number(ex.tokens_in) || 0) + (Number(ex.tokens_out) || 0);
          tr.className = 'hover:bg-slate-900/60';
          tr.innerHTML = `
            <td class="p-2 text-slate-300 font-semibold">${ex.role || '-'}<span class="block text-[9px] text-slate-500 font-normal">${ex.phase || '-'}</span></td>
            <td class="p-2 text-slate-400">${tok.toLocaleString()}</td>
            <td class="p-2 text-slate-400">${ex.duration_s || 0}s</td>
            <td class="p-2"><span class="px-1.5 py-0.5 rounded text-[9px] font-bold ${ex.verdict === 'APROBADO' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-800 text-slate-400'}">${ex.verdict || '-'}</span></td>
          `;
          tbody.appendChild(tr);
        });
      }

      document.getElementById('initiative-modal').classList.remove('hidden');
    }

    function closeInitiativeModal() {
      document.getElementById('initiative-modal').classList.add('hidden');
    }

    window.addEventListener('DOMContentLoaded', () => {
      initGraph();
      initMetrics();
      initMemory();
      initInitiatives();
    });
  </script>
</body>
</html>
HTML_BODY

echo -e "${GREEN}✓ Dashboard interactivo generado en:${NC} $OUTPUT_HTML"

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
