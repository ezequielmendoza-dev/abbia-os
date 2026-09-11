# Workflow DAG — Grafo de Dependencias de los Workflows

> **Versión:** 1.0  
> **Estado:** Activo  
> **Propósito:** Hacer explícitas las dependencias entre fases, agentes y artefactos para permitir ejecución secuencial, paralela o ramificada, y modos de ejecución adaptados al tamaño del trabajo.

---

## 1. El Problema que Resuelve

Los workflows de `ai-agents` (new-feature, bug-fix, etc.) se describen como **narrativas lineales**: Paso 1 → Paso 2 → Paso 3. Pero el proceso real tiene:

- **Fan-out:** Tasks técnicas paralelas (Developer trabaja varias tareas a la vez).
- **Fan-in:** QA espera que *todas* las tareas terminen antes de probar.
- **Back-edges:** Tech Lead `RECHAZADO` devuelve al Analyst; QA `FAIL` devuelve al Developer; hotfix bypassa el pipeline.
- **Gates:** Veredictos que condicionan el flujo (APROBADO → avanza; RECHAZADO → rebota).

**Con DAG:** las dependencias son explícitas y consultables. El Skill Manager (o cualquier orquestador) puede:
1. Saber qué fases pueden correr en paralelo.
2. Detectar cuellos de botella y back-edges.
3. Elegir un **modo de ejecución** según el tamaño del trabajo.

> **Inspiración:** DAG orchestration de Tenet, flujos personalizables de AgEnFK, directed computation graphs de MASFactory (CodeBot).

---

## 2. Conceptos del DAG

| Concepto | Definición | Ejemplo |
|:---|:---|:---|
| **Nodo** | Una unidad de trabajo ejecutada por un agente | `discovery`, `architecture`, `tasks` |
| **Arista** | Dependencia dirigida: B depende de A | `tasks → implement` |
| **Gate** | Nodo de revisión cuyo veredicto ramifica el flujo | `tech-review-1` |
| **Fan-out** | Un nodo que dispara múltiples nodos en paralelo | `tasks → implement (xN)` |
| **Fan-in** | Un nodo que espera que N predecesores completen | `implement (todos) → qa` |
| **Back-edge** | Retorno al nodo origen ante una revisión desfavorable | `qa FAIL → implement` |
| **Modo de ejecución** | Nivel de profundidad con que se ejecuta el DAG | `rápido`, `estándar`, `profundo` |

---

## 3. Formato del Manifest

Cada workflow declara su DAG en un bloque YAML al inicio del archivo Markdown, bajo un marcador `<!-- dag:start -->` … `<!-- dag:end -->`. El procesador (Script/Skill Manager) extrae este bloque como manifest.

```yaml
<!-- dag:start -->
name: new-feature
modes:
  rapido: { truncate: [discovery, ui-design, architecture-decisions] }
  estandar: {}
  profundo: { extra: [adversarial-review] }
nodes:
  discovery:
    agent: analyst
    input: [context.md, feature-request]
    output: [discovery.md]
    parallel: false
  ui-design:
    agent: ui-designer
    input: [spec.md, context.md]
    output: [ui-design.md]
    parallel: false
  architecture:
    agent: architect
    input: [spec.md, ui-design.md]
    output: [architecture.md]
    parallel: false
  tech-review-1:
    agent: tech-lead
    input: [spec.md, architecture.md]
    output: [verdict]
    gate: true
  tasks:
    agent: architect
    input: [architecture.md]
    output: [task-*.md]
    parallel: false
  implement:
    agent: developer
    input: [task.md, architecture.md]
    parallel: true           # fan-out: tantos nodos como tasks
  qa:
    agent: qa
    input: [spec.md, code]
    output: [qa.md]
    parallel: false
  tech-review-2:
    agent: tech-lead
    input: [qa.md]
    output: [verdict]
    gate: true
  deploy:
    agent: devops
    input: [architecture.md]
    output: [release]
    parallel: false
edges:
  - { from: discovery,      to: ui-design }
  - { from: ui-design,      to: architecture }
  - { from: architecture,   to: tech-review-1 }
  - { from: tech-review-1,  to: tasks,        on: APROBADO }
  - { from: tech-review-1,  to: discovery,    on: RECHAZADO, retry: 1, back: true }
  - { from: tech-review-1,  to: ui-design,    on: APROBADO_CON_OBSERVACIONES, back: true }
  - { from: tasks,          to: implement,    type: fan-out }
  - { from: implement,      to: qa,           type: fan-in, all: true }
  - { from: qa,             to: tech-review-2 }
  - { from: tech-review-2,  to: deploy,       on: PASS }
  - { from: tech-review-2,  to: implement,    on: FAIL, back: true }
hotfix:
  enabled: true
  from: [deploy]
  to: [main]
  note: Bypass directo para arreglos críticos, ver workflows/bug-fix.md
<!-- dag:end -->
```

### Elementos del manifest

- **`modes`** — definen transformaciones del DAG por nivel de profundidad (`truncate` elimina nodos, `extra` agrega nodos).
- **`nodes.<nombre>.parallel`** — `true` = se instancia por task (fan-out); `false` = instancia única.
- **`gate`** — el nodo es un punto de revisión con veredicto (`on:` condition).
- **`edges`** — aristas con condiciones (`on:`), retries (`retry`) y tipos (`fan-out`, `fan-in`).
- **`hotfix`** — declara los atajos de emergencia válidos para este workflow.

---

## 4. Modos de Ejecución

El DAG permite 3 modos, seleccionables por el Tech Lead o el Skill Manager según la magnitud del trabajo (inspirado en las flows de BMAD: Full Method / Quick Dev, y el `model_tier` de Tenet):

### 4.1 Modo Rápido (`rapido`)
**Para:** bugs bien definidos, cambios de bajo riesgo, hotfixes.
- **Trunca** los nodos de descubrimiento, diseño UI y decisiones de arquitectura (o los simplifica).
- Pipeline mínimo: `triage → tasks → implement → qa (smoke) → deploy`.
- Regla: **cualquier gate que pida un veredicto se simplifica**, nunca se elimina la validación del QA.

### 4.2 Modo Estándar (`estandar`)
**Para:** features nuevas, cambios de riesgo medio.
- **El DAG completo** como está declarado.
- Es el pipeline anterior (equivalente al flujo narrativo actual de cada workflow).

### 4.3 Modo Profundo (`profundo`)
**Para:** cambios arquitectónicos, features críticas, sistemas legados.
- **Agrega nodos de revisión adversarial** (`adversarial-review`): un crítico independiente (con contexto o sin él, estilo Tenet) revisa el artefacto además del Tech Lead.
- Ejecuta las tareas con granularidad fina y revisa cada fase con gate extra.
- Útil para refactors globales y migraciones.

### Cómo se decide el modo

| Señal | Modo sugerido |
|:---|:---|
| Bug crítico, fix de 1-2 archivos, cambio de config | `rapido` |
| Feature nueva estándar, bug con análisis moderado | `estandar` |
| Cambio de arquitectura, migración, feature crítica de dinero/seguridad, deuda técnica profunda | `profundo` |

La decisión **la confirma el Tech Lead** (no se auto-asigna). El Skill Manager puede recomendarlo basándose en el triage, pero el gate humano es el Tech Lead.

---

## 5. Ejecución del DAG

### Secuenciación
1. `topological sort` sobre las aristas (respetando `on:` conditions del gate).
2. Los nodos sin dependencia pendiente y que cumplen `on:` se marcan como **ejecutables**.
3. Los nodos `parallel: true` se instancian N veces (una por task) y ejecutan en paralelo.
4. Cada gate detiene el flujo hasta recibir veredicto.
5. Los back-edges (`back: true`) reinsertan el nodo origen en la cola de ejecución con `retry` contador.

### Estados de nodo

| Estado | Significado |
|:---|:---|
| `pending` | Esperando dependencias |
| `ready` | Dependencias satisfechas, listo para ejecutar |
| `running` | En ejecución |
| `blocked` | Esperando veredicto humano (gate) |
| `done` | Artifact producido y aprobado |
| `superseded` | No ejecutará (modo truncated o nodo obsoleto por redirección) |

---

## 6. DAGs de los Workflows del Framework

### 6.1 `new-feature` — DAG arriba (§3)

Nodos: `discovery`, `ui-design`, `architecture`, `tech-review-1` (gate: APROBADO/OBS/RECHAZADO), `tasks` (fan-out → `implement` paralelo), `qa` (fan-in), `tech-review-2` (gate: PASS/FAIL), `deploy`.

### 6.2 `bug-fix` — DAG dinámico por categoría

El triage (`bug-triage`) clasifica el bug y **selecciona el sub-DAG apropiado**:

| Categoría | Sub-DAG |
|:---|:---|
| Negocio | `analyst → spec-fix → developer → qa-fix → tech-review` |
| Visual | `ui-designer → developer → qa-fix → tech-review` |
| Arquitectura | `architect → tech-review → tasks → implement → qa → tech-review` |
| Implementación pura | `developer → qa-fix → tech-review` |
| Crítico (hotfix) | `hotfix-path`: directo a deploy con smoke test |

### 6.3 `refactor` — DAG con gates de cobertura

`tech-lead-plan → (si global: architect)` → `test-coverage-gate` (¿hay tests antes?) → `implement-incremental` (fan-out por módulo) → `qa-regression` → `tech-review`.

- **Regla:** si no hay cobertura de tests previa al refactor, el gate `test-coverage-gate` redirige a un nodo `add-tests` antes de permitir la implementación.
- El DAG permite refactor **por módulos en paralelo** (`implement-incremental` fan-out) solo si el Tech Lead declara que los módulos son independientes.

### 6.4 `release` — DAG de verificación previa

`qa-smoke → release-checklists (7 checklists fan-out) → tech-review-release → deploy → post-deploy-health`.

- `qa-smoke` y los checklists corren en paralelo (no hay dependencia cruzada).
- Si `post-deploy-health` falla → back-edge a `rollback` (nodo especial que restaura la versión anterior) → `post-mortem` (redirige a `decisions.md`).

### 6.5 `architecture-change` — DAG con gate de ADR

`tech-lead-trigger → architect-adr (gate: ADR aprobado) → [global-updates | migratory-implementation] → qa → tech-review → devops`.

- El ADR **debe estar aprobado** antes de cualquier cambio de código (similar al `tech-review-1` de new-feature pero con peso de arquitectura).

---

## 7. Validación del DAG

Un manifest válido cumple:

1. **Aciclicidad estructural:** el grafo dirigido (sin contar back-edges) no tiene ciclos. Los back-edges están marcados `back: true` y tienen `retry` acotado.
2. **Cada `edge` referencia nodos existentes.**
3. **Todo nodo con `output` tiene al menos un consumidor** (o se declara final).
4. **Los gates tienen `on:` conditions** — sin condición, no son gate.
5. **Los `modes` que `truncate` nunca eliminan un nodo final** (`deploy`) ni un gate de validación (QA).

La validación la ejecuta `scripts/validate-project.sh` (extensión) o el Skill Manager al cargar un workflow.

---

## 8. Relación con Workflow Memory

- **Decisión de modo:** al iniciar una sesión, el Skill Manager consulta `context-snapshot.md` para sugerir modo.
- **Back-edges:** cada retorno por gate (RECHAZADO/FAIL) queda registrado en `workflow-log.md` (memoria episódica) para que el agente que retoma entienda el reproceso.
- **Retries:** superado el `retry` de un back-edge, el nodo sube a `blocked` y requiere intervención humana (nunca loop infinito).

---

## 9. Referencias

- [Workflow Memory](workflow-memory.md) — la memoria que alimenta la ejecución del DAG.
- [Workflows](../workflows/) — los manifiests inline en cada archivo.
- [Artifact Lifecycle](artifact-lifecycle.md) — estados que los gates validan.
- [tenet-style critics] — inspiración de `modes.profundo` (críticos independientes).