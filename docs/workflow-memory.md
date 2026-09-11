# Workflow Memory — Memoria Persistente del Pipeline

> **Versión:** 1.0  
> **Estado:** Activo  
> **Propósito:** Evitar que el contexto se pierda entre sesiones y agents. Cada ejecución del pipeline deja una huella legible que los agentes futuros consumen automáticamente.

---

## 1. El Problema que Resuelve

El sistema de agentes documentales de `ai-agents` ya persiste *artefactos* (specs, diseños, reportes). Pero **la memoria de la ejecución en sí** — decisiones tomadas, patrones descubiertos, errores cometidos — vive solo en el contexto efímero de una sesión.

**Sin memoria de workflow:**
- Un developer retoma un feature 2 semanas después y no sabe *por qué* la arquitectura tomó cierta forma.
- Un QA descubre un test flaky y nadie lo documenta → se repite el mismo debugging.
- Las decisiones "CONTEXTO DEL PROYECTO" se re-explican en cada sesión → tokens perdidos y contexto inconsistente.

**Con memoria de workflow:** cada agente, al terminar su trabajo, registra una entrada breve. El siguiente agente (o el mismo en una sesión futura) lee las entradas anteriores y retoma sin re-descubrir.

> **Inspiración:** workflow-memory de Compozy, self-correcting doctrine de Tenet, shared brain de Galdr.

---

## 2. Tipos de Memoria

| Tipo | Qué recuerda | Se escribe desde | Se lee en |
|:---|:---|:---|:---|
| **Episódica** | Qué pasó en cada sesión (eventos, resultados, decisiones ad-hoc) | Fin de cada ejecución de agente | Siguientes ejecuciones del mismo feature/área |
| **Semántica** | Hechos persistentes del proyecto (decisiones arquitectónicas, reglas, patrones) | Consolidated / Tech Lead / Architect | Todas las sesiones |
| **Procedimental** | Cómo resolver problemas específicos en este proyecto | Developer / QA / DevOps | Sesiones que enfrentan el mismo problema |

---

## 3. Archivos del Sistema de Memoria

El sistema de memoria vive en `.ai/memory/` (a la par de los documentos permanentes del proyecto).

```
.ai/memory/
├── README.md               ← Contrato de uso (este sistema, copiado al proyecto)
├── workflow-log.md         ← Memoria episódica: log append-only de todas las sesiones
├── decisions-catalog.md    ← Memoria semántica: decisiones indexadas y vigentes
├── patterns-learned.md     ← Memoria procedimental: patrones y lecciones aplicables
└── context-snapshot.md     ← Memoria compactada: resumen ejecutivo para arrancar una sesión
```

### 3.1 `workflow-log.md` — Memoria Episódica (append-only)

Cada ejecución de un agente agrega una entrada. **Nunca se reescribe una entrada existente; solo se agrega o se marca como superseded.** Formato:

```markdown
## [FEAT-042] S3 — Architect (2026-09-11T15:30Z)

- **Insumos consumidos:** spec.md (approved), ui-design.md
- **Decisión:** Evaluar SQLite vs PostgreSQL; elegir PostgreSQL.
- **Razón:** Requisito de transacciones ACID para pagos multi-tenancy.
- **Alternativas descartadas:** SQLite (sin concurrencia de escritura), MongoDB (no transacciones ACID distribuidas).
- **Riesgo detectado:** RT-07 (migración de datos legacy) — se devuelve a Tech Lead.
- **Outputs producidos:** [architecture.md](../features/FEAT-042-slug/architecture.md)
```

Reglas de escritura:

1. **Breve y accionable** — máximo ~6 bullet points. Si necesita más de 10 líneas, la información debe vivir en un artefacto, no en la memoria.
2. **Siempre con fecha ISO-8601** y referencia al agente (`S# — Rol`).
3. **Decisiones ≠ opiniones** — se registra la decisión, la razón y las alternativas (nunca "me parecía mejor Google Cloud" sin el criterio detrás).
4. **Appendix-only** — el Tech Lead puede marcar una entrada como `⚖️ OBSOLETA` apuntando a su reemplazo, pero no borrarla.

### 3.2 `decisions-catalog.md` — Memoria Semántica (estado vigente)

Es un **índice de decisiones** vigentes. Tiene formato de tabla con referencia al detalle en `decisions.md` (que sigue siendo la fuente de verdad de decisiones).

```markdown
| ID | Decisión | Estado | Referencia | Última revisión |
|:---|:---|:---|:---|:---|
| DEC-013 | PostgreSQL como único motor de persistencia | ⚖️ Vigente | [decisions.md](../../decisions.md#dec-013) | 2026-09-11 |
| DEC-014 | Feature flags para lanzamiento gradual | 🔄 En evaluación | [decisions.md](../../decisions.md#dec-014) | 2026-09-12 |
```

Reglas:

1. **No duplica decisiones** — cada fila referencia `decisions.md`; el catálogo es un índice para búsqueda rápida, no un segundo lugar de verdad.
2. **Cambio de estado** — mover una decisión a `🔄 En evaluación` cuando haya propuesta de cambio, y a `⚖️ Vigente`/`✖️ Descartada` al resolver.

### 3.3 `patterns-learned.md` — Memoria Procedimental (lecciones aplicables)

Patrones y lecciones que aceleran el trabajo futuro.

```markdown
## Problema: Tests E2E flaky por dependencia de orden

- **Síntoma:** Prefill de datos de usuario fallaba intermitentemente al correr la suite completa.
- **Causa raíz:** Un test no limpiaba su usuario y otro dependía de estado global compartido.
- **Solución aplicada:** Aislamiento por test + `data-testid` para selectores estables.
- **Aplica a:** [E2E] Cualquier nuevo test que toque autenticación.
```

Reglas:

1. **Formato problema → causa → solución → aplica a** — nada de diarios personales.
2. **Solo patrones reutilizables** — un one-off (ej. error de config de un solo entorno) no va aquí, va al log episódico.
3. **Viven para siempre** — este archivo es de más valor cuanto más tiempo pasa.

### 3.4 `context-snapshot.md` — Memoria Compactada (resumen ejecutivo)

Es la puerta de entrada a la memoria. Generado por el **Skill Manager** al iniciar una sesión — compacta `workflow-log.md` + `decisions-catalog.md` + `patterns-learned.md` en un resumen de ~30 líneas que se inyecta como contexto a los agentes.

- Se regenera en cada sesión (nunca se edita a mano).
- Si el log crece > ~300 líneas o hay > ~20 sesiones desde la última compactación, el Skill Manager propone **compactación mayor** (ver §4).

---

## 4. Ciclo de Vida: Capturar → Compactar → Recordar

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│    CAPTURAR    │ ──▶ │   COMPACTAR    │ ──▶ │    RECORDAR    │
│  Cada agente   │     │ Skill Manager  │     │  Agentes       │
│  escribe en    │     │ al iniciar     │     │  leen snapshot │
│  workflow-log  │     │ sesión:        │     │  + recuerdan   │
└────────────────┘     └────────────────┘     └────────────────┘
```

### Fase 1 — Capturar (al finalizar cada agente)

Todo agente del pipeline, al terminar su participación, **escribe una entrada en `workflow-log.md`** según §3.1. Esto incluye los no-productor de artefactos (Tech Lead agrega su veredicto y el resultado).

> **Automatización:** el script `scripts/finish-phase.sh` cierra la fase registrando la entrada en `workflow-log.md`, la ejecución en `metrics/executions.yaml` y regenerando `context-snapshot.md` (ver `docs/repository-structure.md`). Es la vía recomendada para no depender de que cada agente recuerde registrarse.

### Fase 2 — Compactar (al iniciar la sesión, Skill Manager)

1. Lee los 3 archivos de origen.
2. Descarta entradas episódicas ya incorporadas al snapshot anterior (no re-copiar).
3. Mantiene decisiones vigentes (`⚖️` y `🔄`).
4. Incluye patrones aún relevantes (los patrones marcados `🕰️` del snapshot previo se omiten si ya se aplicaron).
5. Escribe el nuevo `context-snapshot.md`.

### Fase 3 — Recordar (los agentes lo consumen)

Cada agente recibe el `context-snapshot.md` como parte de su contexto de activación, junto con `context.md` del proyecto. La memoria es **contexto, no autoridad**: los artefactos aprobados (spec, architecture) siguen siendo la fuente de verdad. La memoria ayuda a arrancar y a evitar repeticiones, no reemplaza el proceso documental.

---

## 5. Contrato de los Agentes

| Agente | Acción de memoria obligatoria |
|:---|:---|
| **Product Analyst** | Entrada episódica al cerrar discovery; decisiones ambiguas que resolvió |
| **UI Designer** | Entrada episódica con criterios de diseño divergentes que resolvió |
| **Software Architect** | Entrada episódica + actualización del catálogo de decisiones (DEC-xxx) si tomó o invalidó una |
| **Tech Lead** | Entrada episódica con el veredicto de cada gate (APROBADO/OBS/RECHAZADO) y su justificación |
| **Senior Developer** | Entrada episódica con lecciones de implementación; propuesta de patrón si es reutilizable |
| **QA Engineer** | Entrada episódica con el resultado (PASS/FAIL) y hallazgos que pueden re-regresar |
| **DevOps Engineer** | Entrada episódica con hallazgos de pipeline/infra; patrones de despliegue aprendidos |
| **Skill Manager** | Orquesta `Capture → Compact → Recall`; genera el snapshot al iniciar sesión |

---

## 6. Interacción con los Documentos Permanentes

La memoria **no reemplaza** el sistema de artefactos; es complementaria y jerárquicamente inferior:

| Concepto | Autoridad | Se actualiza |
|:---|:---|:---|
| `.ai/context.md`, `architecture.md`, `decisions.md` | Verdad del proyecto | Solo por dueños documentales (update-in-place, R1-R5) |
| `.ai/memory/*` | Registro de ejecución | Append + consolidación por Skill Manager |

Regla general: **si una decisión tiene impacto estructural, se registra en la memoria Y se refleja en el artefacto/`decisions.md`.** La memoria es el registro del *porqué y cómo llegamos ahí*; los artefactos son el *estado vigente*.

---

## 7. Anti-Patrones de la Memoria

- ❌ **Convertir la memoria en un diario:** Entradas de 50 líneas sin acción clara. Si no se puede escribir en 6 bullets, va a un artefacto.
- ❌ **Tratar la memoria como autoridad:** Un patrón de 3 meses no invalida una decisión de arquitectura aprobada. La memoria informa; los artefactos mandan.
- ❌ **Editar entradas históricas:** El `workflow-log.md` es append-only. Corregir → marcar `OBSOLETA`, no borrar.
- ❌ **Duplicar decisiones en `decisions.md` y `decisions-catalog.md`:** El catálogo es índice, no segunda fuente de verdad.
- ❌ **Sobrecargar el snapshot:** El `context-snapshot.md` debe ser un resumen ejecutivo corto; si supera ~50 líneas, la compactación está fallando.
- ❌ **Solo el Developer escribe:** Todos los agentes (incluidos los de design/QA/DevOps) dejan memoria, o el contexto queda sesgado a la implementación.

---

## 8. Referencias

- [Specification-Driven Development](sdd-philosophy.md) — la fuente de verdad del proceso documental.
- [Artifact Lifecycle](artifact-lifecycle.md) — ciclo de vida de los artefactos.
- [Skill Manager](../roles/skill-manager.md) — orquestador del ciclo de memoria.
- [Workflow DAG](workflow-dag.md) — cómo la memoria alimenta la ejecución por dependencias.