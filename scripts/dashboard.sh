#!/usr/bin/env bash

# ==============================================================================
# dashboard.sh — ai-agents Interactive Dashboard & Visualizer
# ==============================================================================
# Genera y abre un dashboard visual interactivo en el navegador para explorar:
#   1. Knowledge Graph (Grafo de decisiones arquitectónicas y dependencias)
#   2. Telemetría y Métricas (Tokens consumidos por rol, tiempos y costos)
#   3. Workflow Memory (Línea de tiempo de sesiones, catálogo y lecciones)
#   4. Estado del Proyecto e Iniciativas Activas (.ai/features/)
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

# Extraer nodos del Knowledge Graph
KG_RAW=$(read_file_or_default "$KG_FILE" "version: 1\nnodes: []\nedges: []")
METRICS_RAW=$(read_file_or_default "$METRICS_FILE" "executions: []")
LOG_RAW=$(read_file_or_default "$LOG_FILE" "(sin entradas en workflow-log.md)")
CATALOG_RAW=$(read_file_or_default "$CATALOG_FILE" "(sin catálogo)")
PATTERNS_RAW=$(read_file_or_default "$PATTERNS_FILE" "(sin patrones aprendidos)")
SNAPSHOT_RAW=$(read_file_or_default "$SNAPSHOT_FILE" "(sin snapshot)")
CONTEXT_RAW=$(read_file_or_default "$CONTEXT_FILE" "(sin context.md)")

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

        <!-- Node Details Panel -->
        <div class="bg-slate-900 border border-slate-800 rounded-xl p-4 flex flex-col justify-between">
          <div>
            <h3 class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">Detalle de Decisión</h3>
            <div id="node-detail-empty" class="text-xs text-slate-500 italic py-8 text-center">
              Haz clic en cualquier nodo del grafo para ver su información y relaciones.
            </div>
            <div id="node-detail-card" class="hidden space-y-3 text-xs">
              <div class="flex items-center justify-between">
                <span id="detail-id" class="px-2 py-0.5 rounded font-mono font-bold bg-sky-500/20 text-sky-400 border border-sky-500/30">ARCH-000</span>
                <span id="detail-status" class="px-2 py-0.5 rounded font-semibold text-[10px]">ACTIVE</span>
              </div>
              <h4 id="detail-title" class="font-bold text-slate-100 text-sm">Título de la Decisión</h4>
              <div class="space-y-1.5 text-slate-300">
                <div><span class="text-slate-500">Depende de:</span> <span id="detail-depends" class="font-mono text-sky-400">[]</span></div>
                <div><span class="text-slate-500">Reemplaza a:</span> <span id="detail-supersedes" class="font-mono text-amber-400">[]</span></div>
                <div><span class="text-slate-500">Conflictos con:</span> <span id="detail-conflicts" class="font-mono text-rose-400">[]</span></div>
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
        <div class="bg-slate-900 border border-slate-800 p-4 rounded-xl">
          <div class="text-xs text-slate-400 font-medium">Costo Estimado (USD)</div>
          <div id="kpi-cost" class="text-2xl font-black text-emerald-400 mt-1">$0.00</div>
          <div class="text-[10px] text-slate-500 mt-1">Tarifa Claude / GPT-4o est.</div>
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

      <!-- Executions Table -->
      <div class="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        <div class="px-5 py-3 border-b border-slate-800 flex items-center justify-between">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider">Historial de Ejecuciones de Agentes</h3>
          <span id="table-count" class="text-xs text-slate-500">0 registros</span>
        </div>
        <div class="overflow-x-auto max-h-80">
          <table class="w-full text-left text-xs text-slate-300">
            <thead class="bg-slate-950 text-slate-400 text-[10px] uppercase font-semibold sticky top-0">
              <tr>
                <th class="py-2.5 px-4">Fecha (UTC)</th>
                <th class="py-2.5 px-4">Iniciativa</th>
                <th class="py-2.5 px-4">Rol</th>
                <th class="py-2.5 px-4">Fase</th>
                <th class="py-2.5 px-4">Tokens In</th>
                <th class="py-2.5 px-4">Tokens Out</th>
                <th class="py-2.5 px-4">Duración</th>
                <th class="py-2.5 px-4">Veredicto</th>
              </tr>
            </thead>
            <tbody id="executions-tbody" class="divide-y divide-slate-800/60 font-mono"></tbody>
          </table>
        </div>
      </div>
    </section>

    <!-- ==================== TAB 3: WORKFLOW MEMORY ==================== -->
    <section id="tab-memory" class="tab-content space-y-6">
      <!-- Snapshot Card -->
      <div class="bg-gradient-to-r from-sky-950/40 to-slate-900 border border-sky-800/40 rounded-xl p-5 shadow-lg">
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center gap-2">
            <span class="text-lg">📸</span>
            <h3 class="text-sm font-bold text-sky-400">Context Snapshot (Memoria Compactada)</h3>
          </div>
          <span class="text-[10px] bg-sky-500/20 text-sky-300 border border-sky-500/30 px-2 py-0.5 rounded font-mono">context-snapshot.md</span>
        </div>
        <div id="snapshot-content" class="prose prose-invert prose-xs max-w-none text-xs text-slate-300 leading-relaxed bg-slate-950/60 p-4 rounded-lg border border-slate-800/80"></div>
      </div>

      <!-- Memory Views Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Workflow Log (Episodic) -->
        <div class="lg:col-span-2 bg-slate-900 border border-slate-800 rounded-xl p-5">
          <h3 class="text-xs font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center justify-between">
            <span>📖 Bitácora Cronológica (Workflow Log)</span>
            <span class="text-[10px] text-slate-500 font-normal">Memoria Episódica</span>
          </h3>
          <div id="log-timeline" class="space-y-4 max-h-[500px] overflow-y-auto pr-2"></div>
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

    <!-- ==================== TAB 4: INICIATIVAS ==================== -->
    <section id="tab-features" class="tab-content space-y-4">
      <div class="bg-slate-900/60 p-4 rounded-xl border border-slate-800 flex items-center justify-between">
        <div>
          <h2 class="text-base font-semibold text-slate-200">Iniciativas del Sistema (.ai/features/)</h2>
          <p class="text-xs text-slate-400">Resumen y estado de las features, bugs, auditorías y refactors.</p>
        </div>
      </div>
      <div id="initiatives-grid" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"></div>
    </section>
  </main>

  <script>
    // --- Data Parsing ---
    let kgData = { nodes: [], edges: [] };
    let metricsData = { executions: [] };

    try {
      const kgRaw = document.getElementById('raw-kg').textContent.trim();
      kgData = jsyaml.load(kgRaw) || { nodes: [], edges: [] };
    } catch (e) { console.error('Error parseando KG YAML:', e); }

    try {
      const metricsRaw = document.getElementById('raw-metrics').textContent.trim();
      metricsData = jsyaml.load(metricsRaw) || { executions: [] };
    } catch (e) { console.error('Error parseando Metrics YAML:', e); }

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

      const totalTokens = totalIn + totalOut;
      document.getElementById('kpi-tokens-total').textContent = totalTokens.toLocaleString();
      document.getElementById('kpi-tokens-in').textContent = totalIn.toLocaleString();
      document.getElementById('kpi-tokens-out').textContent = totalOut.toLocaleString();
      document.getElementById('kpi-sessions').textContent = executions.length;
      document.getElementById('kpi-retries').textContent = retries;
      document.getElementById('kpi-time').textContent = Math.round(totalSec / 60) + ' min';

      // Costo estimado ($3 / 1M in, $15 / 1M out)
      const costEst = ((totalIn * 3 / 1000000) + (totalOut * 15 / 1000000));
      document.getElementById('kpi-cost').textContent = '$' + costEst.toFixed(3);

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

    // --- Tab 4: Initiatives Grid ---
    function initInitiatives() {
      const grid = document.getElementById('initiatives-grid');
      const initiatives = {};

      (metricsData.executions || []).forEach(ex => {
        if (!ex.initiative) return;
        if (!initiatives[ex.initiative]) initiatives[ex.initiative] = { id: ex.initiative, count: 0, tokens: 0, lastTs: ex.ts };
        initiatives[ex.initiative].count++;
        initiatives[ex.initiative].tokens += (Number(ex.tokens_in) || 0) + (Number(ex.tokens_out) || 0);
      });

      Object.values(initiatives).forEach(init => {
        const card = document.createElement('div');
        card.className = 'bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2';
        card.innerHTML = `
          <div class="flex items-center justify-between">
            <span class="font-bold text-sky-400 font-mono text-sm">${init.id}</span>
            <span class="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded">${init.count} fases</span>
          </div>
          <div class="text-xs text-slate-400">Tokens invertidos: <span class="font-bold text-slate-200">${init.tokens.toLocaleString()}</span></div>
          <div class="text-[10px] text-slate-500">Última actividad: ${(init.lastTs || '').replace('T', ' ').replace('Z', '')}</div>
        `;
        grid.appendChild(card);
      });
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
