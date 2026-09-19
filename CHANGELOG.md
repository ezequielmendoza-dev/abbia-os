# CHANGELOG

Todas los cambios notables en este repositorio se documentan en este archivo.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

## [4.0.0] — 2026-09-18

### 🚀 Rebranding e Identidad de Producto: Abbia OS
- **Lanzamiento de Abbia OS v4.0.0** — Transformación formal de `ai-agents` en **Abbia OS** (*Layered Context, Structured Memory, Autonomous Delivery*), un sistema operativo de ingeniería asistida por IA integral.
- **Identidad de Orquestador Explícita ("Abbia")** — Incorporación en todas las plantillas de reglas de IDE (`AGENTS.md`, `cursorrules`, `CLAUDE.md`, `windsurfrules`, `clinerules`, `copilot-instructions.md`, `cursor-rules/general.mdc`) y en `roles/prompt-guide.md` del reconocimiento nativo de **Abbia** como orquestador del sistema ante llamadas conversacionales directas (*"Abbia, debemos crear una feature..."*).
- **Estructura Canónica `.abbia/`** — Sustitución de la carpeta genérica `.ai/` por `.abbia/` en proyectos destino, con submódulo en `.abbia/core` e iniciativas en `.abbia/initiatives/`.
- **CLI Wrapper Unificado (`./abbia`)** — Nuevo ejecutable instalado en la raíz del proyecto para ejecutar comandos directos (`./abbia new`, `./abbia finish`, `./abbia archive`, `./abbia sync`, `./abbia validate`, `./abbia dashboard`, `./abbia serve`, `./abbia watch`, `./abbia update`, `./abbia migrate`).
- **Auto-Regeneración Silenciosa del Dashboard** — Todos los scripts de ciclo de vida (`finish-phase.sh`, `new-initiative.sh`, `archive-initiative.sh`, `sync-initiatives.sh`) actualizan automáticamente `.abbia/dashboard.html` si existe, garantizando que un simple `F5` / reload en el navegador refleje inmediatamente cualquier cambio sin regenerar manualmente.
- **Dashboard en Vivo y Servidor Local con Live Reload (`./abbia serve` / `dashboard.sh --serve` / `--watch`)** — Soporte para levantar un servidor local en tiempo real con recarga automática en el navegador ante modificaciones en `.abbia/` (initiatives, memory, metrics, rules, architecture), más indicador visual y botón de recarga en el header del dashboard.
- **Herramienta de Migración Automatizada (`scripts/migrate-to-abbia.sh`)** — Script interactivo y seguro para migrar proyectos existentes desde la convención `.ai/` o `.stratum/` hacia `.abbia/` preservando iniciativas, historial, submódulos Git y configuraciones de IDE.
- **Compatibilidad Retroactiva Transparente** — `scripts/common.sh` y todos los scripts de automatización detectan dinámicamente proyectos legacy `.ai/` y `.stratum/` y mantienen plena funcionalidad emitiendo avisos formativos para la migración.
- **Identidad y Voz de los Agentes Abbia** — Actualización de todos los roles (`roles/*.md`), prompts y plantillas de IDE (`Cursor`, `Claude Code`, `Windsurf`, `Cline/Roo-Code`, `Copilot`) para operar bajo la metodología y estándares de Abbia OS.
- **Dashboard Visual Abbia OS** — Rebranding completo del visualizador web (`scripts/dashboard.sh`) con estética premium, marca Abbia OS, lectura de `.abbia/` y badges actualizados.
- **Suite de Pruebas y Fixtures Actualizados** — `tests/test-runner.sh` y `examples/golden-project/` migrados a `.abbia/` con cobertura del 100% (32/32 pruebas superadas, incluyendo tests de auto-refresh, live reload y migración).

## [3.7.0] — 2026-09-18

### Agregado
- **Suite de Pruebas Automatizadas (`tests/test-runner.sh`)** — Suite integral de 26 pruebas automáticas que valida en un entorno temporal aislado el ciclo de vida completo: `setup-ide.sh`, `new-initiative.sh`, `finish-phase.sh`, `validate-project.sh`, `archive-initiative.sh`, `sync-initiatives.sh` y la conformidad del fixture de referencia.
- **Proyecto de Referencia Canónico (`examples/golden-project/`)** — Repositorio modelo 100% canónico y autocontenido con `.ai/context.md`, `business-rules.md`, `architecture.md`, `decisions.md`, `glossary.md`, `knowledge-graph.yaml`, memoria, telemetría, iniciativa archivada (`FEAT-001-user-auth/`) e iniciativa activa (`FEAT-002-order-checkout/`).
- **Context Contracts en Todos los Roles (`roles/*.md`)** — Cada rol (`analyst`, `ui-designer`, `architect`, `tech-lead`, `developer`, `qa`, `devops`, `skill-manager`) define ahora explícitamente su contrato de contexto de entrada: **Contexto Requerido**, **Contexto Condicional** y **Contexto Prohibido**, evitando consumo innecesario de tokens y desvíos de responsabilidad.

### Modificado
- **Consolidación del Sistema de Decisiones Arquitectónicas** — Se eliminó el archivo redundante `.ai/memory/decisions-catalog.md`. Las decisiones se gestionan como fuentes duales directas en `.ai/knowledge-graph.yaml` (grafo estructurado) y `.ai/decisions.md` (ADR en prosa), sincronizándose automáticamente hacia `.ai/memory/context-snapshot.md` mediante `scripts/common.sh`.
- **Refactorización de Skill Manager (`roles/skill-manager.md`)** — Redefinido como **Capability & Context Advisor**, asesorando en el descubrimiento de skills, reglas de precedencia, catálogo externo (skills.sh) y mantenimiento del snapshot de memoria sin ficciones de orquestación de DAG en runtime.
- **Desacoplamiento del Ciclo de Vida Documental SDD** — `scripts/new-initiative.sh` crea únicamente los artefactos de arranque correspondientes a la fase inicial (`spec.md` y `decision.md` para features; `bug-report.md` para bugs), dejando que cada rol (`ui-designer`, `architect`, `qa`) genere sus artefactos cuando el flujo lo demanda.
- **Validación Progresiva del Ciclo de Vida** — `scripts/validate-project.sh`, `scripts/sync-initiatives.sh` y `scripts/common.sh` ahora evalúan la coherencia documental según el estado real y las fases completadas en cada iniciativa.
- **Nombres Canónicos de Roles y Artefactos Homogeneizados** — Alineación en `roles/analyst.md`, `roles/ui-designer.md`, `roles/architect.md`, `roles/developer.md`, `roles/qa.md`, `templates/feature-folder-template.md` y `templates/ide-configs/AGENTS.md`.

## [3.6.0] — 2026-09-18

### Agregado
- **Plantilla Estándar `.gitattributes` con `merge=union`** — Nueva plantilla `templates/ide-configs/gitattributes` que define la estrategia nativa de merge `union` para archivos append-only de telemetría y memoria (`.ai/memory/workflow-log.md` y `.ai/metrics/executions.yaml`), resolviendo automáticamente adiciones concurrentes entre ramas.
- **Validación de Higiene de Git en `validate-project.sh`** — Nuevo paso de verificación que detecta si archivos derivados/caché (`dashboard.html`, `context-snapshot.md`, `aggregates.yaml`) están siendo rastreados por Git indebidamente y valida la presencia de `.gitignore` y `.gitattributes` con `merge=union`.
- **Soporte CLI para `auto`/`next` en `new-initiative.sh`** — Permite invocar `bash .ai/agents/scripts/new-initiative.sh FEAT auto mi-slug` para autodescubrir y asignar el siguiente ID sin intervención manual.

### Modificado
- **Detección Dinámica de IDs en `new-initiative.sh`** — El cálculo del siguiente ID numérico disponible ahora escanea dinámicamente las carpetas existentes en `.ai/features/` y `.ai/archive/`, eliminando la competencia y conflictos por la línea de contador en `.ai/context.md`.
- **Instalador `setup-ide.sh` Mejorado para Git** — El paso de configuración de Git ahora inicializa tanto las exclusiones en `.gitignore` (`.ai/sessions/`, `.ai/dashboard.html`, `.ai/memory/context-snapshot.md`, `.ai/metrics/aggregates.yaml`) como las directivas `merge=union` en `.gitattributes`.
- **Documentación de Buenas Prácticas de Merge** — Actualizados `README.md`, `AGENTS.md`, `templates/ide-configs/AGENTS.md` y `docs/project-integration.md` con guías claras para trabajo colaborativo multi-desarrollador y hooks `post-merge`.

## [3.5.1] — 2026-09-16

### Modificado
- **Obligatoriedad de Parámetros de Telemetría para Agentes (Regla R6)** — Se reforzó la regla documental R6 en `AGENTS.md`, `templates/ide-configs/AGENTS.md`, `CLAUDE.md`, `cursorrules`, `windsurfrules`, `clinerules`, `copilot-instructions.md`, `roomodes`, `cursor-rules/general.mdc`, y en todos los roles (`roles/*.md`):
  - Los agentes tienen ahora la instrucción explícita e ineludible de invocar `finish-phase.sh` pasando obligatoriamente sus flags de telemetría (`--model <MODELO>`, `--tokens-in <IN>`, `--tokens-out <OUT>`, `--duration <SEGUNDOS>`, `--source <measured|estimate>`).
  - Se eliminó de los roles y workflows la indicación de "omitir flags de tokens dejando valores null", indicando que es responsabilidad directa del agente auto-reportar o estimar con criterio de ingeniería el consumo de su sesión para alimentar el Dashboard y la telemetría del proyecto.
- **Workflows Actualizados con Comandos de Cierre Completos** — `workflows/new-feature.md` y `workflows/bug-fix.md` ahora especifican llamadas completas a `finish-phase.sh` con flags de modelo, tokens, duración y veredicto en cada uno de sus pasos.
- **Documentación de Telemetría Sincronizada** — Actualizado `docs/agent-metrics.md` y `roles/prompt-guide.md` para reflejar el nuevo estándar de captura y reporte obligatorio por parte de los agentes autónomos.

## [3.5.0] — 2026-09-16

### Agregado
- **Integración con OpenRouter Live Pricing API (Cero Hardcoding)** — `scripts/dashboard.sh` consulta en tiempo real la API pública de OpenRouter (`https://openrouter.ai/api/v1/models`) para obtener las tarifas actualizadas de más de 400 modelos de IA (Gemini, Claude, GPT, DeepSeek, Qwen, Mistral, etc.), calculando el costo estimado en USD de cada sesión y del proyecto completo con caché en `localStorage` y soporte offline.
- **Modal de Transparencia de Costos y Metodología** — Nuevo diálogo interactivo en el dashboard accesible desde el KPI de Costo en USD que detalla la fórmula matemática, la fuente en vivo de OpenRouter y un buscador de tarifas por modelo.
- **Soporte de Modelo y Proveedor en Telemetría** — `scripts/finish-phase.sh` acepta `--model <NOMBRE>` (ej: `gemini-3.7-flash`, `claude-3.7-sonnet`, `deepseek-r1`) y `--provider <NOMBRE>` (ej: `opencode`, `antigravity`, `cursor`), registrándolos en `executions.yaml` y generando agregados `per_model` y `per_provider` en `aggregates.yaml`.
- **`aggregates.yaml` generado automáticamente** — `scripts/finish-phase.sh` ahora invoca un mini-parser Python al cerrar cada fase y regenera `.ai/metrics/aggregates.yaml` con estadísticas agrupadas por fase, rol, modelo e iniciativa (`tokens_total`, `duration_s`, `sample`, `null_tokens`, `retry_rate`). Ya no requiere intervención manual del Skill Manager.
- **Métricas en `context-snapshot.md`** — `scripts/common.sh` incluye ahora un bloque de telemetría en el snapshot automático: total de sesiones, sesiones con tokens medidos y alerta si hay sesiones sin telemetría real.
- **Banner de estado vacío en Telemetría del Dashboard** — `scripts/dashboard.sh` muestra un banner de advertencia accionable (con snippet de comando) cuando todas las entradas de `executions.yaml` tienen `tokens_in: null`.

### Corregido
- **Validación de `INITIATIVE` en `finish-phase.sh`** — Ahora acepta tanto la forma corta `FEAT-NNN` como la forma larga `FEAT-NNN-slug` (nombre completo de la carpeta de iniciativa). El ID se normaliza a `FEAT-NNN` para `executions.yaml` y `workflow-log.md`, mientras que la ruta completa se conserva en el mensaje de outputs.
- **Inferencia de ROL insensible a mayúsculas** — La inferencia de rol por fase ahora usa `PHASE_LOWER` para evitar fallos con fases como `"Spec"` o `"QA"` pasadas con mayúsculas.

### Modificado
- **Instrucción de tokens en todos los roles** — `roles/analyst.md`, `architect.md`, `developer.md`, `qa.md`, `tech-lead.md`, `ui-designer.md`, `devops.md`: Los comandos R6 de cierre de fase ahora incluyen `--tokens-in`, `--tokens-out`, `--duration` y `--source measured` como flags opcionales con ejemplos de valores reales y nota explicativa de cómo obtenerlos del IDE.
- **Instrucción de tokens en workflows** — `workflows/new-feature.md` (10 comandos) y `workflows/bug-fix.md` (7 comandos) incluyen comentario `# Flags opcionales: --tokens-in <N>...` en cada bloque de cierre de fase.
- **`roles/prompt-guide.md` Tip 5 expandido** — Tabla completa de flags disponibles, lista de fases canónicas del DAG, instrucción de cómo obtener tokens en el IDE, ejemplo completo y descripción de los 4 efectos del `finish-phase.sh`.
- **Advertencia de fase no canónica** — `finish-phase.sh` advierte (sin error) cuando la fase no coincide con los nombres del DAG (`analysis`, `ui-design`, `architecture`, etc.), ayudando a normalizar registros históricos como `"Spec"`, `"UI"`, `"Implementation"`.
- **Recordatorio de tokens en output final** — `finish-phase.sh` muestra un recordatorio al final de la ejecución si los tokens quedaron como `null`, con el comando exacto a agregar en la próxima llamada.

---

## [3.4.0] — 2026-09-12

### Agregado
- **`scripts/archive-initiative.sh` (Archivador Automático e Interactivo)** — Nuevo script de automatización que archiva de forma segura una iniciativa de `.ai/features/` a `.ai/archive/`:
  - **Quality Gate:** Valida que `qa.md` tenga veredicto explícito `APROBADO` o `PASS` (con bypass `--force` opcional).
  - **Knowledge Graph Reconciliation:** Reescribe automáticamente rutas de referencias (`ref: features/...` $\rightarrow$ `ref: archive/...`) en `.ai/knowledge-graph.yaml`.
  - **Memoria Persistente:** Registra el evento de pase a histórico en `.ai/memory/workflow-log.md` y regenera `.ai/memory/context-snapshot.md`.
  - **Modo Interactivo:** Soporte de confirmación interactiva en consola (`--prompt`).
- **Regla Documental R6 (Cierre Mandatorio y Telemetría)** — Establecida como regla crítica en `AGENTS.md` y todas las configuraciones de IDE (`CLAUDE.md`, `cursorrules`, `windsurfrules`, `clinerules`, `roomodes`, `copilot-instructions.md`, `.cursor/rules/`):
  - Todo agente debe ejecutar obligatoriamente `bash .ai/agents/scripts/finish-phase.sh <INICIATIVA> <FASE> [ROL]` antes de finalizar su turno o entregar respuestas, garantizando la telemetría veraz en `executions.yaml`, el log en `workflow-log.md` y el snapshot de contexto.
  - Actualizados todos los roles (`roles/*.md`) y workflows (`new-feature.md`, `bug-fix.md`) con comandos CLI explícitos de fin de fase.
### Corregido
- **Eliminación de Estimaciones Sintéticas (6,500 tokens mock)** — Se eliminó la inyección arbitraria de ejecuciones de prueba (`tokens_in: 4500, tokens_out: 2000`) en `scripts/sync-initiatives.sh`.
- **Integridad y Precisión de Telemetría en `scripts/dashboard.sh`** — El dashboard ahora distingue de forma estricta entre métricas reales medidas (`measured` con valores reales) y ejecuciones sin medición (`null` o sin telemetría), mostrando guiones (`—`) o indicadores claros de "sin telemetría" en lugar de inventar o inflar números artificiales.
- **Limpieza de Caracteres en Títulos de Proyecto (BSD sed)** — Corregida la expresión regular en `scripts/dashboard.sh` para evitar truncar caracteres finales en macOS.

---

## [3.3.1] — 2026-09-12

### Agregado
- **Panel de Proyecto & Contexto en `scripts/dashboard.sh`** — Nueva pestaña `🏢 Proyecto` y encabezado dinámico en la barra de navegación que muestra el nombre del proyecto, estado del ciclo de vida, tipo de sistema, repositorio, ruta local, objetivos de negocio (§2), actores/permisos (§3), stack tecnológico (§4), ficha técnica y visor completo de `.ai/context.md`.
- **Modal "Acerca de ai-agents OS" (About Modal)** — Diálogo interactivo accesible desde el navbar y la ficha técnica que documenta la arquitectura del framework, la metodología Spec-Driven Development (SDD), los 8 roles especializados, workflows con DAG, los 4 sistemas de memoria persistente y la referencia rápida de comandos CLI.
- **`scripts/sync-initiatives.sh --fix` (Auto-Healer de Migración Legacy)** — Modo de auto-reparación documental que detecta iniciativas creadas en versiones previas a v3.2 o con artefactos faltantes (`decision.md`, `ui-design.md`, `qa.md`, etc.), scaffolds automáticos, normalización de veredictos semánticos en `qa.md` y depuración automática de placeholders del template en `.ai/knowledge-graph.yaml`.
- **Flujo de Actualización Resiliente en `scripts/update-ai-agents.sh`** — Integración automática de `sync-initiatives.sh --fix` y `validate-project.sh` dentro del actualizador de un solo comando, permitiendo que cualquier proyecto heredado o con discrepancias documentales se actualice y auto-sane de manera transparente.

### Modificado
- **Rediseño UI/UX Completo en `scripts/dashboard.sh`** — Arquitectura de visualización 100% full-width (`w-full max-w-[1600px]`):
  - Organización modular por **Sub-Tabs** en Proyecto (5 tabs), Reglas (2 tabs) y Memoria (4 tabs) eliminando columnas estrechas y scrolls horizontales en tablas Markdown.
  - **Grafo ADR 2D**: Modo dual (Lienzo interactivo / Catálogo tabular), chips de filtrado (Todas, Features, Bugs), barra de herramientas de zoom (➕, ➖, 100%, 🎯 Ajustar, 📐 Cuadrícula), estilizado dark-modern con `drawThreshold: 0` y parser resiliente de YAML.
  - **Iniciativas**: Resumen de 6 KPIs, búsqueda en vivo, selector de ordenamiento, cuadrícula responsiva, paginación configurable y modal de detalle enriquecido con matriz de artefactos SDD, telemetría y snippets CLI.
  - **Telemetría**: Normalización de identificadores (`normalizeInitId`) para cruce consistente entre IDs cortos y nombres de carpetas de iniciativas.
- **`scripts/validate-project.sh`** — Verificación del Knowledge Graph mejorada para descontar placeholders de ejemplo del template y advertir con tip accionable para auto-reparar con `sync-initiatives.sh --fix` ante discrepancias documentales.
- **`docs/project-integration.md`** — Documentación del comando `sync-initiatives.sh --fix` en las secciones de actualización y migración de proyectos legados.

---

## [3.3.0] — 2026-09-11

### Agregado
- **`scripts/dashboard.sh` (Visualizador Interactivo)** — Generador y visor HTML autónomo en el navegador para explorar de forma interactiva el Knowledge Graph de decisiones (canvas Vis.js con filtros y zoom), Telemetría de consumo de tokens y costos (gráficos Chart.js por rol y fase), línea de tiempo de memoria (`workflow-log.md`, catálogo, patrones) y matriz de iniciativas activas sin dependencias de backend.
- **`scripts/sync-initiatives.sh` (Auto-Reconciliador)** — Herramienta para escanear `.ai/features/` y sincronizar automáticamente cualquier iniciativa histórica o activa pendiente en `workflow-log.md`, `decisions-catalog.md`, `knowledge-graph.yaml`, `executions.yaml` y regenerar `context-snapshot.md`.
- **Protocolo de Cierre Mandatorio (Hand-off) en Roles (`roles/*.md`)** — Instrucción explícita de fin de fase en cada rol (`analyst`, `architect`, `developer`, `qa`, etc.) para ejecutar `finish-phase.sh` y evitar la omisión de registros.
- **Reglas Modulares de Cursor (`.cursor/rules/*.mdc`)** — Nuevo directorio de plantillas `templates/ide-configs/cursor-rules/` con archivos `.mdc` (`general.mdc`, `architect.mdc`, `developer.mdc`, `qa.mdc`) que aprovechan el sistema de activación contextual (`globs`, `alwaysApply`, `description`) de Cursor IDE.
- **Custom Modes para Roo-Code / Cline (`.roomodes`)** — Plantilla `templates/ide-configs/roomodes` con la definición JSON de los 8 roles del framework y sus restricciones de herramientas (`read`, `edit`, `command`, `browser`, `mcp`) para ejecución controlada.
- **Localization Step en Workflows (`new-feature.md`, `bug-fix.md`)** — Sub-paso formal previo a la implementación donde el Developer identifica explícitamente los archivos, módulos y símbolos a modificar/crear antes de escribir código, reduciendo el consumo de tokens y evitando modificaciones colaterales.
- **Self-Healing QA Loop (`new-feature.md`, `bug-fix.md`)** — Protocolo estructurado de autoreparación cuando QA emite veredicto `RECHAZADO`: generación de diagnóstico estructurado en `qa.md`, aplicación de parche inmediato por el Developer y re-evaluación en bucle acotado (máximo 3 iteraciones).
- **Living Implementation Tasks (`technical-task.md`)** — Lista de tareas viva e interactiva con checkboxes Markdown (`- [ ]`) por fases para rastreo incremental de avance.
- **Matriz de Asignación de Modelos por Rol (Tiered Models)** — Documentada en `roles/README.md` la estrategia recomendada de modelos según la carga cognitiva del rol (Reasoning/Pro para Analyst/Architect/Tech Lead; Balanced/Code para Developer/QA; Fast/Lite para Skill Manager/DevOps).

### Modificado
- **`scripts/setup-ide.sh`** — Actualizado a v3.3.0 con nuevas opciones de menú interactivo para instalar las reglas modulares de Cursor (`.cursor/rules/*.mdc`) y los modos personalizados de Roo-Code (`.roomodes`).
- **`scripts/validate-project.sh`** — Añadida validación de dependencias en `knowledge-graph.yaml`, sintaxis de veredictos en `qa.md`, y chequeo de registro en `workflow-log.md` por cada iniciativa en `.ai/features/`.
- **`README.md`, `AGENTS.md`, `templates/ide-configs/AGENTS.md`** — Actualizados con las nuevas capacidades y plantillas de la versión 3.3.0.

---

## [3.2.5] — 2026-09-11

### Agregado
- **`scripts/finish-phase.sh`** — Cierre de fase automatizado. Registra una entrada append-only en `.ai/memory/workflow-log.md`, una ejecución en `.ai/metrics/executions.yaml` (mode, tokens, duration, attempts, verdict, `source: estimate|measured`) y regenera `.ai/memory/context-snapshot.md` de forma automática. Resuelve el hueco de enforcement por el cual los sistemas v3.2.0 quedaban con templates vacíos si no intervenía el orquestador. Uso: `bash .ai/agents/scripts/finish-phase.sh <INICIATIVA> <FASE> [ROL] [OPCIONES]` — el rol se infiere de la fase si se omite.
- **`common.sh`** — Nuevos helpers reutilizables: `initiative_id_pattern` (patrón de ID sin slug), `AGENT_ROLES` (roles del pipeline) y `regenerate_context_snapshot <PROJECT_ROOT>` (compacía workflow-log + decisions-catalog + patterns-learned en el snapshot).

### Modificado
- **`scripts/validate-project.sh`** — Los sistemas v3.2.0 ahora validan **contenido**, no solo existencia: `workflow-log.md` sin entradas de sesión, `executions.yaml` sin ejecuciones reales y `knowledge-graph.yaml` sin nodos (solo template) reportan WARN "existe pero vacío/template". Así se distingue "tiene el archivo" de "tiene datos".
- **README.md, AGENTS.md, `templates/ide-configs/AGENTS.md`, `docs/repository-structure.md`** — Tabla de scripts ampliada con `finish-phase.sh`.
- **`docs/workflow-memory.md` (Fase 1), `docs/agent-metrics.md` (Fase 1)** — Documentan el cierre de fase via `finish-phase.sh` como vía recomendada para garantizar el registro.

---

## [3.2.4] — 2026-09-11

### Agregado
- **Tipos de iniciativa `AUDIT` y `REF`** — Además de `FEAT` y `BUG`, el sistema documental soporta iniciativas de auditoría/seguridad (`AUDIT-NNN-slug`) y refactors (`REF-NNN-slug`). Ambos tienen **estructura libre**: el validador no exige documentos concretos, solo verifica que la carpeta no esté vacía. Se registran en `.ai/context.md` junto a los demás IDs.

### Modificado
- **`scripts/common.sh`** — Nueva teoría central de iniciativas: `INITIATIVE_TYPES` ("FEAT BUG AUDIT REF"), patrón de nomenclatura dinámico (`initiative_name_pattern`), archivos obligatorios por tipo (`required_files_for`, vacío = estructura libre) y versión legible para mensajes (`initiative_types_readable`). DRY: validador y bootstrap consumen estos helpers en lugar de hardcodear el patrón.
- **`scripts/validate-project.sh`** — Usa el patrón de nomenclatura central; `FEAT` y `BUG` siguen exigiendo sus documentos (spec/ui-design/architecture/qa/decision y bug-report/qa respectivamente); `AUDIT`/`REF` se validan como estructura libre (error solo si la carpeta está vacía). Aplica también a `.ai/archive/`.
- **`scripts/new-initiative.sh`** — Modo interactivo extendido (1-4) y crea estructura libre (README.md de inicio) para `AUDIT`/`REF`. Seed de `## Registro de IDs` en context.md ampliado con AUDIT y REF.
- **`docs/naming-conventions.md`** — Nueva sección de identificadores especiales (AUDIT/REF) con reglas de estructura libre y ejemplos.
- **`docs/project-integration.md` §4.5**, `README.md`, `AGENTS.md` y `templates/ide-configs/AGENTS.md` — Actualizadas las referencias a nomenclatura y al uso de `new-initiative.sh` con los tipos nuevos.

---

## [3.2.3] — 2026-09-11

### Agregado
- **Guía de migración desde la v1.x del framework** (`docs/project-integration.md` §4.5) — Documenta cómo actualizar un proyecto heredado que se integró en la era v1.x/v2.0 (antes del `update-ai-agents.sh` y del salto a v3.0): actualización manual del submódulo, activación de los sistemas v3.2.0, regeneración de reglas IDE, adaptación de features existentes (requisito nuevo de `ui-design.md`) y limpieza del sparse-checkout obsoleto (`agents/` → `roles/`).

### Modificado
- **`docs/project-integration.md` §8** — Corregido el ejemplo de sparse-checkout que referenciaba `agents templates` (estructura de la era v1 que ya no existe; el directorio pasó a llamarse `roles/`). Ahora lista los directorios actuales (`roles templates workflows checklists scripts docs`) y advierte sobre el patrón antiguo.

---

## [3.2.2] — 2026-09-11

### Agregado
- **`scripts/update-ai-agents.sh`** — Actualización del framework en un solo comando. Detecta la raíz del proyecto, actualiza el submodule `.ai/agents` al último commit (o a un tag pasado como argumento, ej. `bash .ai/agents/scripts/update-ai-agents.sh v3.2.2`), commitea el puntero del submódulo en el proyecto y ejecuta `setup-ide.sh --auto` para activar los sistemas v3.x que falten. Reemplaza el proceso manual de 4 pasos (cd submodule → checkout → git add/commit → setup).

### Modificado
- **`setup-ide.sh` (v1.8.0) — modo no-interactivo `--auto`** — Añadido el flag `--auto`: inicializa la estructura `.ai/` (incl. sistemas v3.2.0), configura `.gitignore` y omite la generación de reglas de IDEs (evita sobrescribir copias del proyecto). Usado por `update-ai-agents.sh`; también puede ejecutarse manualmente con `bash setup-ide.sh --auto`.

---

## [3.2.1] — 2026-09-11

### Corregido
- **`setup-ide.sh` no creaba estructuras de los sistemas v3.2.0** — Al ejecutar la inicialización de la carpeta `.ai/`, el script solo creaba los 5 documentos permanentes originales (`context.md`, `business-rules.md`, `architecture.md`, `decisions.md`, `glossary.md`). Los sistemas nuevos de v3.2.0 quedaban dormidos hasta que el usuario los creara manualmente. Ahora `setup-ide.sh` (v1.7.0) crea automáticamente: `.ai/memory/` con sus 4 archivos seed, `.ai/metrics/executions.yaml` y `.ai/knowledge-graph.yaml`. Todos los archivos se saltan si ya existen (idempotente).
- **`validate-project.sh` fallaba con carpetas vacías** — Con bash 3.2 (macOS) y `set -u`, iterar `"${dirs[@]}"`/`"${archived_dirs[@]}"` sobre un array vacío lanzaba *unbound variable* (exit 1) cuando `.ai/features/` o `.ai/archive/` estaban vacíos — el caso exacto de un proyecto recién inicializado. Los loops sobre iniciativas activas y archivadas se guardan ahora con `if [ ${#dirs[@]} -gt 0 ]` (con mensaje `INFO` cuando no hay iniciativas).

### Modificado
- **`validate-project.sh` — validación de sistemas v3.2.0** — Añadidos chequeos tipo `WARN` (no bloqueantes) para `.ai/knowledge-graph.yaml`, `.ai/memory/` (verificando los 4 archivos seed) y `.ai/metrics/executions.yaml`. La ausencia de estos archivos no rompe la validación existente, compatible con proyectos anteriores a v3.2.0.

---

## [3.2.0] — 2026-09-11

### Agregado
- **Knowledge Graph ligero** (`docs/knowledge-graph.md` + `templates/knowledge-graph.yaml`) — Grafo de relaciones entre decisiones arquitectónicas (ADRs) modelado como nodos/aristas tipadas (`depends_on`, `supersedes`, `related`, `conflicts_with`), inspirado en Ogcode. Permite calcular el impacto de cambios por transitividad sin embeddings. El grafo es un índice de relaciones; `decisions.md` sigue siendo la fuente de verdad.
- **Métricas de agentes** (`docs/agent-metrics.md` + `templates/metrics-executions.yaml`) — Observabilidad del pipeline inspirada en AgEnFK: registro append-only por ejecución (tokens in/out, duración, fase, attempts, veredicto) en `.ai/metrics/executions.yaml` + agregados regenerados por el Skill Manager (`aggregates.yaml`). Habilitan decisiones sobre el sistema de agentes (fases costosas, retry rate, eficiencia de tokens) sin modificar el proceso documental.

### Corregido
- **Versiones de roles inconsistentes** — `roles/devops.md` y `roles/ui-designer.md` quedaron en v1.0 mientras el pipeline pasó a v3.0. Alineados todos los roles a **v3.0** (incluido `roles/skill-manager.md`, cuyo frontmatter pasó de `1.2` → `3.0`). Actualizada la tabla de versiones en `docs/versioning-strategy.md` (que seguía declarando v2.0) y el comentario de estructura en `README.md` y `AGENTS.md`. El campo `Versión: \`1.0\`` dentro de los output formats (ej. `ui-design.md`, `architecture.md`) se documenta explícitamente como versión del **documento de salida**, no del agente.
- **CHANGELOG con secciones duplicadas** — Existían dos bloques `## [2.0.0]` (2026-06-25 y 2026-06-22) y dos `## [2.0.1]` (2026-06-27 y 2026-06-22) fuera de orden. Fusionado el contenido histórico de las versiones de 2026-06-22 dentro de las entradas canónicas y eliminadas las secciones duplicadas. El CHANGELOG ahora tiene una única sección por versión en orden descendente.

### Modificado
- `templates/github-action-ci.yml` — El template de CI pasa de validar solo la estructura documental a ser **multi-lenguaje**: conserva el job `validate-ai-structure` (con verificación de balance de bloques DAG) y agrega un job `language-checks` con matriz Node/Python/Go que detecta el manifest presente (`package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`), instala dependencias y corre los tests.
- `docs/versioning-strategy.md` — Añadida la sección **Versionado de Skills** (MAJOR.MINOR en frontmatter, mismas reglas semánticas que los agentes, sin obligación de alinearse a la MAJOR del framework). Los skills ya declaraban `version: 1.0` en su frontmatter; faltaba la política documentada.
- `skills/README.md` — Verificado: la estructura solo lista directorios y skills reales; las categorías tecnológicas (`frontend/`, `backend/`, …) están documentadas como fuentes de skills `type: tech` externas (no como carpetas del repo).
- `AGENTS.md` (raíz) y `templates/ide-configs/AGENTS.md` — Aclarada la relación entre ambos (raíz = contribuir al framework; template = consumirlo en un proyecto) con referencias cruzadas explícitas para evitar la percepción de duplicidad.
- `README.md` — **Reescritura completa** del archivo principal: reestructurado como experiencia de usuario (Qué es → Quick Start → Qué tiene → Flujo de trabajo → Ejemplos → Guía de integración → Documentación completa). Incluye las 15 skills, los 5 workflows, los 4 sistemas nuevos (Memory, DAG, Knowledge Graph, Metrics) y la tabla completa de documentación. Se eliminaron las secciones redundantes y se reorganizó para que el usuario nuevo pueda empezar en 3 pasos.
- `AGENTS.md` (raíz) — Árbol de estructura actualizado para incluir `knowledge-graph.md`, `agent-metrics.md`, `workflow-memory.md`, `workflow-dag.md` y las 15 skills organizadas por categoría.
- `templates/ide-configs/AGENTS.md` — Añadidas las referencias a `knowledge-graph.yaml`, `.ai/memory/*` y `.ai/metrics/*` en la tabla de documentos permanentes.
- `docs/project-ai-structure.md` — Actualizado árbol `.ai/` y añadidas secciones de `knowledge-graph.yaml`, `memory/` y `metrics/` con su ciclo de vida.
- `docs/repository-structure.md` — Árbol del repo reconstruido (roles v3.0, skills/, scripts/, sistemas, mermaid actualizado, convenciones v3.2.0).
- `roles/README.md` — Versión 2.0→3.0, añadido skill-manager, sección "Agentes de Soporte", referencia a `skills/`.

---

## [3.1.0] — 2026-09-11

### Agregado
- **10 nuevas Framework Skills metodológicas** (`type: method`) — El catálogo de skills del framework pasa de 5 a 15:
  - `skills/analysis/ux-heuristics.md` — Evaluación y diseño de UX con heurísticas (Nielsen, a11y WCAG 2.1 AA).
  - `skills/architecture/backend-architecture.md` — Capas, manejo de errores y contratos de servicios backend.
  - `skills/architecture/database-design.md` — Modelado de entidades, índices, migraciones y SQL vs NoSQL.
  - `skills/architecture/performance-tuning.md` — Optimización medida (métricas, cache, scaling).
  - `skills/architecture/ai-integration.md` — Integración de IA/LLMs como componente con contrato.
  - `skills/development/frontend-patterns.md` — Componentes, estado y rendimiento frontend.
  - `skills/development/mobile-development.md` — Apps móviles, offline-first y decisiones de plataforma.
  - `skills/qa/testing-automation.md` — Automatización sostenible de tests y anti-flakiness.
  - `skills/qa/security-audit.md` — Auditoría de seguridad: authN/Z, secretos, dependencias y threat modeling.
  - `skills/workflow/devops-pipeline.md` — Diseño de CI/CD, entornos y observabilidad.
- **Sistema de Workflow Memory** (`docs/workflow-memory.md`) — Memoria persistente del pipeline (`Capture → Compact → Recall`) para que el contexto sobreviva entre sesiones. Define `.ai/memory/` (`workflow-log.md`, `decisions-catalog.md`, `patterns-learned.md`, `context-snapshot.md`), tipos de memoria y el contrato de escritura de cada rol.
- **Sistema de Workflow DAG** (`docs/workflow-dag.md`) — Grafo de dependencias explícitas (nodos, aristas, gates, fan-out/fan-in, back-edges) para cada workflow, con **3 modos de ejecución**: `rápido`, `estándar` y `profundo` (con revisión adversarial).
- **Manifest DAG en los 5 workflows** — `new-feature.md`, `bug-fix.md` (sub-DAGs por categoría de bug), `refactor.md`, `release.md`, `architecture-change.md` declaran ahora su DAG en bloques `<!-- dag:start -->`/`<!-- dag:end -->`.
- **Template `templates/dag-manifest.yaml`** — Plantilla reutilizable para declarar DAGs custom.

### Modificado
- `skills/README.md` — Estructura actualizada a las 5 categorías metodológicas reales del framework (analysis, architecture, development, qa, workflow) + catálogo de las 15 skills. Las categorías por tecnología (frontend/backend/database/…) se documentan como fuentes de skills `type: tech` externas.
- `skills/registry.md` — Añadida sección §2.1 "Categorías Framework" mapeando categorías → roles → skills.
- `roles/skill-manager.md` — v1.1 → v1.2. Añadido el **Contrato de Workflow Memory** (orquesta `Capture → Compact → Recall`) y la **Ejecución por DAG** (extracción, validación, selección de modo y secuenciación de nodos).

### Nota
- El sistema DAG es **descriptivo** v1.0: los manifiests documentan la estructura de dependencias para orquestadores (Skill Manager, scripts, herramientas externas) y humanos. La ejecución determinista por maquinaria se puede implementar sobre estos manifiests.

---

## [3.0.0] — 2026-07-18

### Agregado
- **Specification-Driven Development (SDD)** — Evolución arquitectónica completa del repositorio. `ai-agents` pasa de ser una biblioteca de agentes a ser un **Framework** de ciclo de vida de desarrollo.
- **Artefacto de Discovery (`discovery.md`)** — Nuevo documento para que el Analyst evalúe opciones funcionales de manera consultiva antes de producir la especificación, eliminando la asunción ciega de contexto.
- **Documentos Core SDD:** `docs/sdd-philosophy.md` y `docs/artifact-lifecycle.md` explican la filosofía, los 7 estados de una feature y el principio de "los documentos como fuente de verdad".

### Modificado
- `roles/analyst.md` — Modificado para actuar como consultor estratégico, introduciendo la fase de descubrimiento y el requerimiento de producir un `discovery.md` si el alcance es ambiguo.
- `roles/architect.md`, `roles/tech-lead.md`, `roles/developer.md`, `roles/qa.md` — Actualizados para imponer estrictamente el consumo de artefactos sobre el contexto conversacional.
- `workflows/new-feature.md` — Incorporada la fase opcional de Discovery al diagrama y flujo de creación de features.
- `scripts/new-initiative.sh` — Refactorizado para crear de forma automatizada `discovery.md` (opcionalmente) al inicializar una nueva feature.
- `templates/feature-spec.md` — Agregado metadato de estado de feature.
- `README.md` — Reestructurado completamente en torno al paradigma SDD.

---

## [2.0.1] — 2026-06-27

### Agregado
- **Evaluación y Recomendación de Skills Externas (skills.sh)** (`FEAT-005-skills-sh-integration`) — Capacidad del `Skill Manager` para analizar dependencias del proyecto, detectar brechas tecnológicas y recomendar proactivamente la instalación de skills desde [skills.sh](https://www.skills.sh/) para potenciar agentes específicos del pipeline.

### Modificado
- `roles/skill-manager.md` — Actualizado el workflow de discovery y activation para incluir el análisis de brechas (Gap Analysis) y el listado de sugerencias de `skills.sh`.
- `docs/skill-discovery.md` — Añadida sección de "Adquisición de Skills Externas" y descripción del proceso de análisis de brechas.
- `docs/skill-manager.md` — Integrado el paso de recomendaciones del catálogo en el flujo de pipeline e interacción humana.
- `skills/registry.md` — Incorporado [skills.sh](https://www.skills.sh/) como catálogo externo de referencia de donde provienen las skills `L1` y `L2`.
- `README.md`, `AGENTS.md` y `templates/ide-configs/AGENTS.md` — Actualizada la responsabilidad del `Skill Manager` para incluir el diagnóstico tecnológico y recomendación de skills.

### Eliminado
- `analyst.md` (raíz) — v1.0 obsoleta, reemplazada por `roles/analyst.md` v2.0
- `architect.md` (raíz) — v1.0 obsoleta, reemplazada por `roles/architect.md` v2.0
- `developer.md` (raíz) — v1.0 obsoleta, reemplazada por `roles/developer.md` v2.0
- `qa.md` (raíz) — v1.0 obsoleta, reemplazada por `roles/qa.md` v2.0
- `tech-lead.md` (raíz) — v1.0 obsoleta, reemplazada por `roles/tech-lead.md` v2.0
- `agent-definitions.md` (raíz) — reemplazado por `docs/agent-definitions.md` con contenido real

### Razón
Los archivos de la raíz eran versiones v1.0 sin headers markdown, sin Chain of Thought, sin output format estructurado y sin guías de activación. Mantenerlos junto a las versiones v2.0 en `roles/` generaba confusión sobre cuál era la fuente canónica. La raíz queda limpia — los agentes viven en `roles/`.

---

## [2.0.0] — 2026-06-25

### Agregado
- **Sistema de Orquestación y Descubrimiento de Skills** — Evolución arquitectónica completa. `ai-agents` ya no es una biblioteca de skills tecnológicas, sino un orquestador que descubre capacidades desde el proyecto, entorno del usuario y extensiones.
- Nuevo rol: `Skill Manager` (`roles/skill-manager.md`), encargado de descubrir, priorizar y resolver conflictos de skills como paso previo a la ejecución.
- Documentación del motor de orquestación en `docs/`: `skill-discovery.md`, `skill-resolution.md`, `external-skill-providers.md`, y `skill-context.md`.
- Scaffolding de **Framework Skills** (Skills metodológicas): `analysis/requirements-discovery.md`, `architecture/api-design.md`, `development/code-review.md`, `qa/test-strategy.md`, `workflow/release-readiness.md`.
- `roles/analyst.md` v2.0 — Chain of Thought, Output Format estructurado, guía de activación
- `roles/architect.md` v2.0 — Chain of Thought, Output Format estructurado, guía de activación
- `roles/tech-lead.md` v2.0 — Decision Framework, Chain of Thought, Output Format estructurado
- `roles/developer.md` v2.0 — Chain of Thought, Output Format estructurado, guía de activación
- `roles/qa.md` v2.0 — Clasificación de bugs, Chain of Thought, Output Format estructurado
- `roles/devops.md` v1.0 — Nuevo agente especializado para infraestructura y deployments
- `roles/prompt-guide.md` v1.0 — Guía completa de prompts por agente con ejemplos reales
- `docs/agent-definitions.md` — Meta-documento con estándar de diseño de agentes
- `templates/feature-spec.md` — Template completo para especificaciones funcionales
- `templates/architecture-spec.md` — Template completo para diseños técnicos
- `templates/technical-task.md` — Template para tareas técnicas de desarrollo
- `templates/qa-report.md` — Template para reportes de QA
- `templates/bug-report.md` — Template para reporte de bugs
- `templates/project-context.md` — Template para el contexto del proyecto (`.ai/context.md`)
- `checklists/frontend-review.md` — Checklist de revisión frontend
- `checklists/backend-review.md` — Checklist de revisión backend
- `checklists/database-review.md` — Checklist de revisión de base de datos

### Modificado
- `skills/registry.md` — Transformado de un índice estático de tecnologías a un catálogo dinámico de reglas de orquestación, priorización (Shadowing) y resolución de conflictos.
- Todos los roles (`analyst.md`, `architect.md`, `ui-designer.md`, `tech-lead.md`, `developer.md`, `qa.md`, `devops.md`) actualizados para incluir la sección **Skill Awareness**, obligándolos a subordinar su conocimiento a las skills activas detectadas.
- `README.md` y `AGENTS.md` actualizados para reflejar el nuevo paradigma de orquestación agnóstica.
- Repositorio inicializado como Git repo con remote `https://github.com/ezequielmendoza-dev/abbia-os.git`
- Rama principal renombrada de `master` a `main`

### Eliminado
- Todas las skills tecnológicas hardcodeadas (`frontend/`, `backend/`, `database/`, etc.). El conocimiento tecnológico ahora debe vivir en el proyecto (`.skills/`) o en el entorno del usuario (ej. Gemini CLI, Claude Code).

## [1.6.6] — 2026-06-24

### Agregado
- **Protocolo de Clarificación Proactiva** — Nueva sección en `templates/ide-configs/AGENTS.md` que establece la regla global de interacción: los agentes preguntan al usuario sobre ambigüedades de negocio/alcance antes de producir su output, pero mantienen autonomía total en decisiones técnicas de su área.
- Paso 0 en el `Chain of Thought` de todos los agentes (`analyst.md`, `ui-designer.md`, `architect.md`, `developer.md`, `qa.md`, `devops.md`) y en el `Decision Framework` de `tech-lead.md` — Cada agente evalúa proactivamente si necesita clarificación antes de actuar.

### Modificado
- `roles/prompt-guide.md` — Actualizado el Tip 4 para reflejar que los agentes ahora preguntan por diseño, sin necesidad de indicárselo en el prompt.

---

## [1.6.5] — 2026-06-24

### Modificado
- `roles/prompt-guide.md`, `README.md`, `templates/ide-configs/AGENTS.md` y todos los roles bajo `roles/` — Se eliminó la instrucción redundante de copiar y pegar (o pasar explícitamente) el archivo `.ai/context.md` en los prompts de activación y ejemplos de los agentes, permitiendo que la IA lo lea de forma autónoma e implícita según la regla global 1 del IDE.

---

## [1.6.4] — 2026-06-23

### Modificado
- `workflows/new-feature.md` y `workflows/bug-fix.md` — Se actualizó el paso de interacción interactiva final para requerir la validación y guía de commit y push de cambios, así como indicarle activamente al usuario si procede iniciar el workflow para una nueva release.

---

## [1.6.3] — 2026-06-23

### Agregado
- `scripts/common.sh` — Creado utilitario compartido para centralizar colores de consola, cálculo de rutas base y la función de detección de directorio raíz del proyecto (`detect_project_root`).

### Modificado
- `scripts/setup-ide.sh`, `scripts/new-initiative.sh` y `scripts/validate-project.sh` — Refactorizados para consumir `common.sh`, eliminando definiciones redundantes y simplificando el código de cabecera.
- `README.md`, `AGENTS.md` y `templates/ide-configs/AGENTS.md` — Se actualizó la estructura y se documentaron detalladamente los propósitos y modos de uso de todos los scripts de automatización.

---

## [1.6.2] — 2026-06-23

### Modificado
- `workflows/new-feature.md` y `workflows/bug-fix.md` — Agregado un paso de interacción interactiva al final del pipeline (después de la aprobación del Tech Lead) para preguntar al usuario si requiere realizar el commit (siguiendo Conventional Commits) y actualizar la versión del proyecto.

---

## [1.6.1] — 2026-06-23

### Modificado
- `templates/ide-configs/AGENTS.md` — Agregada referencia explícita a `.ai/context.md` en el encabezado principal para guiar a la IA al contexto del proyecto inmediatamente.
- `README.md` y `scripts/setup-ide.sh` — Sincronizada la versión del proyecto a la última versión estable.

---

## [1.6.0] — 2026-06-23

### Agregado
- **Checklist de Seguridad**: Nuevo checklist `checklists/security-review.md` para auditoría de autenticación, validación de datos, control de acceso y manejo de secretos.
- **Checklist de Rendimiento**: Nuevo checklist `checklists/performance-review.md` para verificación de optimizaciones de front/back, consultas de base de datos y leaks de memoria.
- **Checklist de Despliegue (Release)**: Nuevo checklist `checklists/release-review.md` para control operacional durante ventanas de despliegue y planes de contingencia.
- **Script de Bootstrap (`new-initiative.sh`)**: Script automatizado `scripts/new-initiative.sh` para crear la estructura de una feature (FEAT) o bug (BUG) y registrarla en el context de forma automatizada.
- **Script de Validación (`validate-project.sh`)**: Script automatizado `scripts/validate-project.sh` para verificar el cumplimiento de las reglas documentales locales y nomenclatura.
- **Plantilla de GitHub Actions (`github-action-ci.yml`)**: Plantilla `templates/github-action-ci.yml` para correr la validación de conformidad de forma automatizada en el pipeline de CI/CD.

### Modificado
- `roles/README.md` — Integrado el rol de `UI Designer` a la tabla del pipeline principal y al diagrama visual de flujo de desarrollo.
- `templates/project-context.md` — Añadida la sección `## Registro de IDs` de forma predeterminada para el seguimiento de iniciativas.
- `AGENTS.md` y `templates/ide-configs/AGENTS.md` — Actualizados para documentar y referenciar los nuevos checklists y scripts locales de automatización.

---

## [1.5.0] — 2026-06-23

### Modificado
- `workflows/bug-fix.md` — Rediseñado el workflow de corrección de bugs para hacerlo dinámico según la severidad e impacto del bug. Se definieron caminos específicos (sub-pipelines) de agentes (Analyst, UI Designer, Architect, Developer, QA y DevOps).
- `templates/ide-configs/AGENTS.md` — Actualizado el flujo del pipeline del bug-fix en las plantillas del IDE para reflejar su flexibilidad.

---

## [1.4.0] — 2026-06-23

### Agregado
- **Agente UI Designer**: Nuevo rol de agente experto (`roles/ui-designer.md`) responsable de proponer layouts responsivos, estados de interfaz detallados (carga, éxito, error, vacío) y accesibilidad (a11y).
- **Plantilla de especificación de interfaz**: Nueva plantilla `templates/ui-design-spec.md` para documentar la propuesta de UI/UX en `.ai/features/FEAT-NNN-slug/ui-design.md`.
- **Checklist de UI/UX Review**: Nuevo checklist `checklists/ui-review.md` para auditar la consistencia visual y de interacción antes de mergear cambios.

### Modificado
- `workflows/new-feature.md` — Integrado el paso de diseño de UI (`ui-design.md`) en el pipeline de desarrollo antes del diseño técnico de la arquitectura.
- `templates/feature-folder-template.md` — Actualizada la estructura de carpeta por feature y el ciclo de vida para incluir a `ui-design.md`.
- `AGENTS.md` y `templates/ide-configs/AGENTS.md` — Se agregó al UI Designer en la tabla de roles de agentes, prompts de instanciación, checklists y workflows globales.

---

## [1.3.0] — 2026-06-23

### Agregado
- **Auto-Contextualización / Bootstrap**: Se extendió el rol del `Product Analyst` (`roles/analyst.md`) y las plantillas de configuración (`templates/ide-configs/AGENTS.md`) con la capacidad de inicializar el archivo `.ai/context.md` de forma guiada y automatizada escaneando el código y la estructura de directorios del proyecto.

### Modificado
- `README.md` — Se actualizó el Paso 3 de la guía de integración detallando cómo usar la IA del IDE para autogenerar el contexto del proyecto a partir del código existente.

---

## [1.2.0] — 2026-06-23

### Agregado
- `templates/ide-configs/` — Plantillas de configuración para IDEs de IA como Cursor (`.cursorrules`), Claude Code (`CLAUDE.md`), Windsurf (`.windsurfrules`), Cline (`.clinerules`), y Copilot (`copilot-instructions.md`).
- `scripts/setup-ide.sh` — Script automatizado interactivo para inicializar la estructura `.ai/` y copiar las plantillas de configuración de IDEs de IA en el proyecto.
- `docs/project-integration.md` — Guía detallada para integrar `ai-agents` como submódulo Git.

### Modificado
- `README.md` — Reescrita la guía de integración como un paso a paso detallado y limpio que detalla la estructura y el uso del script `setup-ide.sh`.

---

## [1.1.0] — 2026-06-22

### Agregado

**Estrategia documental:**
- `docs/documentation-strategy.md` — Manifiesto filosófico del sistema documental: conocimiento permanente vs. trabajo por feature, 5 reglas documentales, ciclo de vida de documentos y anti-patrones
- `docs/naming-conventions.md` — Convenciones de nomenclatura: `FEAT-NNN`, `BUG-NNN`, `ARCH-NNN`, branches de Git y commits (Conventional Commits)
- `docs/project-ai-structure.md` — Guía completa de la estructura `.ai/` para proyectos: propósito de cada carpeta (`context.md`, `business-rules.md`, `architecture.md`, `decisions.md`, `glossary.md`, `features/`, `archive/`, `sessions/`)

**Template:**
- `templates/feature-folder-template.md` — Template que documenta la estructura de una carpeta de feature (`FEAT-XXX/`), propósito de cada archivo (`spec.md`, `architecture.md`, `qa.md`, `decision.md`) y ciclo de vida completo

**Workflows (nueva carpeta):**
- `workflows/new-feature.md` — Pipeline completo de nueva feature integrado con `.ai/` y `features/FEAT-XXX/`
- `workflows/bug-fix.md` — Proceso de corrección de bugs con triaje, escalación de críticos y post-mortem
- `workflows/refactor.md` — Workflow de refactorización con principio de comportamiento externo inmutable
- `workflows/release.md` — Proceso de deployment a producción con smoke test en staging, plan de rollback y flujo de hotfix
- `workflows/architecture-change.md` — Cambios estructurales del sistema con ADR obligatorio y enfoque por fases

### Modificado

**Estructura del repositorio (Renombre de Carpeta):**
- Carpeta principal `agents/` renombrada a `roles/` para evitar la redundancia de rutas (`.ai/agents/agents/` -> `.ai/agents/roles/`) al integrar el repositorio como submodule en la ruta recomendada `.ai/agents/`.
- Actualizadas todas las referencias internas y externas en guías de activación, prompts, workflows y documentación para apuntar a `roles/` en lugar de `agents/`.

**Agentes — Sección `Documentation Rules` agregada a todos:**
- `roles/analyst.md` — Reglas para documentos de feature y actualización de docs permanentes (business-rules, glossary)
- `roles/architect.md` — Reglas para architecture.md de feature y actualización de architecture.md global
- `roles/tech-lead.md` — Rol como guardián de los estándares documentales del equipo
- `roles/developer.md` — Scope documental acotado: output del agente y escalación de conocimiento permanente
- `roles/qa.md` — qa.md como único output documental y reporte de conocimiento permanente descubierto
- `roles/devops.md` — Scope de infraestructura y context.md como fuente de verdad operacional

**README principal:**
- Actualizado para reflejar el nuevo sistema documental
- Sección "Sistema Documental" con el modelo de dos niveles y las 5 reglas
- Tabla de convenciones de nomenclatura
- Estructura de carpetas actualizada (workflows/ ahora existe, roles/ reemplaza a agents/)
- Flujo de trabajo con paso de archivado de features
- Buenas prácticas actualizadas con reglas de actualización documental
- Versión bumped a `v1.1.0`

---

## [1.0.0] — 2026-06-01

### Agregado
- `analyst.md` v1.0 — Agente Product Analyst (versión inicial)
- `architect.md` v1.0 — Agente Software Architect (versión inicial)
- `developer.md` v1.0 — Agente Senior Developer (versión inicial)
- `qa.md` v1.0 — Agente QA Engineer (versión inicial)
- `tech-lead.md` v1.0 — Agente Tech Lead (versión inicial)
- `agent-definitions.md` — Template base de estructura de agente

---

*ai-agents library | [github.com/ezequielmendoza-dev/abbia-os](https://github.com/ezequielmendoza-dev/abbia-os)*
