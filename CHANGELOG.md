# CHANGELOG

Todas los cambios notables en este repositorio se documentan en este archivo.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

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
- Repositorio inicializado como Git repo con remote `https://github.com/ezequielmendoza-dev/ai-agents.git`
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

*ai-agents library | [github.com/ezequielmendoza-dev/ai-agents](https://github.com/ezequielmendoza-dev/ai-agents)*
