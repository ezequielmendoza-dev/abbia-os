# Knowledge Graph — Grafo Ligero de Decisiones Arquitectónicas

> **Versión:** 1.0  
> **Estado:** Activo  
> **Propósito:** Representar las **relaciones entre decisiones arquitectónicas** (ADRs) como un grafo consultable, para detectar impacto de cambios, decisiones heredadas y deudas técnicas de forma rápida — sin recurrir a embeddings ni bases vectoriales.

---

## 1. El Problema que Resuelve

`decisions.md` es un log **append-only y lineal**: cada decisión se agrega al final con referencias textuales a sus predecesoras (ej. "Supersedida por ARCH-012"). Esta narrativa lineal tiene un límite:

- **Impacto invisible:** Al cambiar `ARCH-005`, ¿qué decisiones posteriores dependen de ella? Hay que leer todo el log.
- **Deudas heredadas:** ¿Qué decisión de hace 3 meses sigue vigente e influye sobre la arquitectura actual?
- **Dependencias implícitas:** Una decisión "técnica" a veces invalida o condiciona una "de arquitectura" sin que el texto lo haga explícito.

**Con un grafo:** las decisiones son **nodos** y sus relaciones son **aristas tipadas**. El impacto de cambiar una decisión se obtiene recorriendo sus aristas salientes/entrantes (transitive closure) — igual que `memory_recall` de Ogcode, pero con aristas explícitas en vez de similaridad semántica.

> **Inspiración:** Ogcode (grafo de conocimiento persistente con relación Topic→Concept→Fact y `memory_recall` por relevancia), RAG de decisiones en LongSeas.
>
> **Diferencia clave con Ogcode:** aquí el grafo es **ligero y determinista** — se escribe a mano en YAML por el Architect/Tech Lead, sin embeddings. Es "Knowledge Graph" porque modela *relaciones entre decisiones*, no conocimiento abierto del dominio.

---

## 2. Propósito del Grafo

El Knowledge Graph responde a preguntas que el log lineal no puede:

| Pregunta | Cómo la responde el grafo |
|:---|:---|
| ¿Qué decisiones dependen de `ARCH-005`? | Aristas salientes de `ARCH-005` (dependents) |
| ¿Qué decisiones dejó de impactar `ARCH-003`? | Arista `supersedes`, nodo marca `OVERRIDDEN` |
| Antes de modificar pagos, ¿qué debo revisar? | Recorrido por `related`/`depends-on` desde `ARCH-012` |
| ¿Hay dos decisiones en conflicto? | Arista `conflicts-with` entre nodos |
| ¿Cuál es la decisión raíz del sistema? | Nodos sin predecesores (`root: true`) |

**Regla de oro:** el grafo es un **índice de relaciones**, no una segunda fuente de verdad. El texto completo de cada decisión vive en `decisions.md`; el grafo solo referencia (`ref`) cada nodo.

---

## 3. Ubicación y Formato

El grafo vive en `.ai/knowledge-graph.yaml` (a la par de `decisions.md`).

```yaml
# --- metadata ---
version: 1
updated: 2026-09-11
maintained_by: architect

# --- nodos: UNA fila por decisión del proyecto (ARCH-NNN) ---
nodes:
  - id: ARCH-001
    title: Microservicios para el módulo de pagos
    status: ACTIVE            # ACTIVE | DEPRECATED | SUPERSEDED
    root: true                # no depende de ninguna decisión previa
    supersedes: []            # ARIDs que esta decisión reemplaza
    ref: ../decisions.md#arch-001

  - id: ARCH-012
    title: PostgreSQL como motor único
    status: ACTIVE
    depends_on: [ARCH-001]
    related: [ARCH-009]
    ref: ../decisions.md#arch-012

  - id: ARCH-018
    title: Event bus para sincronización multi-tenant
    status: PENDING            # propuesta aún en discusión
    depends_on: [ARCH-012]
    conflicts_with: [ARCH-015]
    ref: ../decisions.md#arch-018

# --- aristas explícitas (opcional: para relaciones no cubiertas por los campos) ---
edges:
  - from: ARCH-012
    to: ARCH-015
    type: conflicts-with
    note: "PostgreSQL único vs. sharding: limitación de escritura distribuida"
```

### Tipos de relación

| Campo | Tipo de arista | Significado |
|:---|:---|:---|
| `depends_on` | `depends-on` | Esta decisión asume que la otra está vigente |
| `supersedes` | `supersedes` | Esta decisión reemplaza a la(s) indicada(s) |
| `related` | `related` | Compatibles y relacionadas sin dependencia |
| `conflicts_with` | `conflicts-with` | Incompatibles bajo ciertas condiciones |

> `edges` es una **vía de escape** para relaciones que los campos estándar no cubren (ej. relación etiquetada con detalle). En proyectos medianos casi siempre basta con los campos de `nodes`.

---

## 4. Estados de un Nodo

| Estado | Significado | Reglas |
|:---|:---|:---|
| `ACTIVE` | Decisión vigente, se aplica hoy | No editar: solo se deprecia o supersede |
| `DEPRECATED` | Dejó de aplicarse sin reemplazo directo | Marcar tras verificar que nada la referencia |
| `SUPERSEDED` | Reemplazada por otra | La arista entrante `supersedes` lo demuestra |
| `PENDING` | Propuesta en evaluación | El Analyst/Architect la usa antes de decidir |

**Regla de sincronización con `decisions.md`:** cuando se agrega un `ARCH-NNN` en `decisions.md`, se agrega su nodo al grafo en la **misma sesión** (mismo PR). Un nodo sin `ref` es un error de proceso.

---

## 5. Cómo se Consume

El **Software Architect** mantiene el grafo al aprobar `ARCH-NNN`. El **Tech Lead** lo consulta antes de cada gate. El resto de los agentes no lo edita.

```markdown
### Incidencia de cambio en ARCH-012 (PostgreSQL único)
Dependientes directos: ARCH-018 (event bus), ARCH-020 (sharding pago)
Conflicto potencial: ARCH-015 (caché distribuida)
```

**Integración con el sistema de memoria:** el grafo es una fuente de **memoria semántica** — se referencia desde `decisions-catalog.md` (§3.2 de `workflow-memory.md`) y se compacta dentro de `context-snapshot.md` como "decisiones vigentes con dependencias activas".

---

## 6. Consultas Útiles (Transitividad)

Para detectar el conjunto completo de decisiones afectadas por cambiar `ARCH-X`, recorrer transitivamente `depends_on` y `related` salientes. Un **script de validación ligero** (`scripts/validate-knowledge-graph.sh`) puede:

1. Verificar que cada `ref` existe en `decisions.md`.
2. Verificar que no haya aristas a nodos inexistentes.
3. Verificar que `supersedes` no apunte a un nodo ya `SUPERSEDED` (evitar cadenas muertas).
4. Listar nodos `ACTIVE` con dependientes = 0 (candidatos a deprecar).

---

## 7. Anti-Patrones

- ❌ **Grafo como fuente de verdad:** El texto vive en `decisions.md`; el grafo solo indexa relaciones. Si hay divergencia, manda `decisions.md`.
- ❌ **Grafo monstruoso:** Si supera ~50 nodos o la relación `related` es más frecuente que `depends_on`, el grafo degenera en "esponja" sin señal — volver a la pregunta "¿esto cambia la arquitectura?".
- ❌ **Editar nodos `ACTIVE`:** Como en `decisions.md`, los cambios se modelan como nueva decisión → arista `supersedes`, nunca reescribiendo el pasado.
- ❌ **Confundir con DAG de workflows:** El Knowledge Graph modela *decisiones*, el DAG de workflows modela *ejecución*. No se mezclan.

---

## 8. Referencias

- [Workflow Memory](workflow-memory.md) — donde el grafo alimenta la memoria semántica.
- [Workflow DAG](workflow-dag.md) — grafo de *ejecución* (distinto propósito).
- [Project AI Structure](project-ai-structure.md) — `decisions.md` como fuente de verdad de ADRs.
- [Software Architect](../roles/architect.md) — dueño del grafo.