# Estructura .ai/ — Guía de Integración para Proyectos

> **Versión:** 3.0  
> **Estado:** Vigente  
> **Última actualización:** Septiembre 2026

---

## Propósito

Este documento define la estructura estándar `.ai/` que todo proyecto integrado con `ai-agents` debe tener.

La carpeta `.ai/` es la **memoria del proyecto**: el lugar donde vive todo el conocimiento que los agentes necesitan para trabajar correctamente, sin repetir contexto en cada conversación.

---

## Estructura Completa

```
proyecto/
└── .ai/
    │
    ├── context.md              # Identidad del proyecto
    ├── business-rules.md       # Reglas de negocio permanentes
    ├── architecture.md         # Arquitectura actual del sistema
    ├── decisions.md            # Log de decisiones arquitectónicas
    ├── glossary.md             # Glosario del dominio
    ├── knowledge-graph.yaml    # Grafo de relaciones entre decisiones (NUEVO)
    │
    ├── memory/                 # Memoria persistente del pipeline (NUEVO)
    │   ├── workflow-log.md     # Memoria episódica (append-only)
    │   ├── decisions-catalog.md# Memoria semántica (decisiones indexadas)
    │   ├── patterns-learned.md # Memoria procedimental (lecciones)
    │   └── context-snapshot.md # Memoria compactada (resumen para sesión)
    │
    ├── metrics/                # Métricas del pipeline (NUEVO)
    │   └── executions.yaml     # Registro por ejecución de agente
    │
    ├── features/               # Trabajo activo por feature
    │   ├── FEAT-001-nombre/
    │   │   ├── discovery.md    # (Opcional) Análisis previo a la spec
    │   │   ├── spec.md
    │   │   ├── ui-design.md
    │   │   ├── architecture.md
    │   │   ├── qa.md
    │   │   └── decision.md
    │   └── FEAT-002-nombre/
    │       └── ...
    │
    ├── archive/                # Features completadas (read-only)
    │   └── FEAT-000-nombre/
    │       └── ...
    │
    └── sessions/               # Sesiones de trabajo guardadas (opcional)
        └── 2026-06-22-nombre-de-sesion.md
```

---

## Documentos Permanentes

### `context.md`

**Propósito:** La fuente de verdad sobre qué es el proyecto, cómo está construido y cómo se trabaja en él.

**Contenido mínimo:**

```markdown
# Contexto del Proyecto: [Nombre]

## Descripción
[Qué hace el proyecto, para quién, cuál es el problema que resuelve]

## Stack Tecnológico
- Frontend: [tecnología]
- Backend: [tecnología]
- Base de datos: [tecnología]
- Infraestructura: [plataforma]

## Entornos
- Development: [URL/descripción]
- Staging: [URL/descripción]
- Production: [URL/descripción]

## Convenciones de Código
- [Lista de convenciones importantes]

## Módulos Principales
- [Lista de módulos con descripción breve]

## Registro de IDs
- Último FEAT asignado: FEAT-XXX
- Último BUG asignado: BUG-XXX
- Último ARCH asignado: ARCH-XXX
```

**Cuándo actualizar:** Cuando cambia el stack, el equipo, los entornos o las convenciones.

**Template base:** [`templates/project-context.md`](../templates/project-context.md)

---

### `business-rules.md`

**Propósito:** Centraliza las reglas de negocio del dominio que no cambian con cada feature. Son invariantes del sistema.

**Contenido mínimo:**

```markdown
# Reglas de Negocio — [Nombre del Proyecto]

## Módulo: [Nombre del módulo]

| ID | Regla | Fuente | Vigente desde |
|----|-------|--------|---------------|
| RN-001 | [descripción precisa] | [stakeholder/doc] | YYYY-MM-DD |
```

**Cuándo actualizar:** Cuando el Analyst identifica una nueva regla permanente o cuando cambia una regla existente.

**Diferencia clave:** Las reglas temporales o específicas de una feature van en `features/FEAT-XXX/spec.md`. Este archivo solo contiene reglas que aplican a TODO el sistema, independientemente de qué feature se esté trabajando.

---

### `architecture.md`

**Propósito:** Describe la arquitectura **actual** del sistema en producción. No la arquitectura aspiracional ni la futura.

**Contenido mínimo:**

```markdown
# Arquitectura del Sistema — [Nombre del Proyecto]

## Última actualización: YYYY-MM-DD

## Visión General
[Diagrama Mermaid o descripción de alto nivel]

## Módulos y Responsabilidades
[Tabla de módulos con descripción]

## Decisiones Arquitectónicas Vigentes
[Referencias a ARCH-XXX en decisions.md]

## Dependencias Externas
[Servicios de terceros, APIs externas, SDKs]
```

**Cuándo actualizar:** Cuando una feature aprobada cambia la arquitectura global. El Architect es el responsable de mantener este documento.

**Regla crítica:** Si `architecture.md` describe algo que ya no existe en producción, el documento es **incorrecto** y debe corregirse inmediatamente.

---

### `decisions.md`

**Propósito:** Log append-only de decisiones arquitectónicas y técnicas importantes. Responde a la pregunta: *"¿por qué el sistema está diseñado de esta manera?"*

**Formato de cada entrada:**

```markdown
## ARCH-001: [Título de la decisión]

**Fecha:** YYYY-MM-DD  
**Estado:** Vigente | Supersedida por ARCH-XXX  
**Feature relacionada:** FEAT-XXX (si aplica)

### Contexto
[Por qué fue necesario tomar esta decisión]

### Decisión
[Qué se decidió, de forma precisa]

### Alternativas descartadas
- **[Alternativa A]:** [por qué se descartó]
- **[Alternativa B]:** [por qué se descartó]

### Consecuencias
[Qué implica esta decisión hacia el futuro]
```

**Cuándo agregar una entrada:** Cuando el Tech Lead o el Architect toman una decisión técnica no obvia que debería quedar registrada para que futuros desarrolladores entiendan por qué el sistema es como es.

**Regla importante:** Este es el único documento donde se permite el crecimiento por adición. Cada nueva decisión se agrega al final — nunca se elimina ni reemplaza una entrada anterior. Si una decisión cambia, se agrega una nueva entrada con el estado "Supersede a ARCH-XXX".

---

### `knowledge-graph.yaml`

**Propósito:** Grafo ligero de relaciones entre decisiones arquitectónicas. Permite calcular transitivamente qué decisiones dependen, superseden o están en conflicto con una decisión dada — sin recorrer `decisions.md` completo.

**Formato:** YAML con nodos (ADRs) y aristas tipadas (`depends_on`, `supersedes`, `related`, `conflicts_with`). Cada nodo referencia su entrada en `decisions.md` mediante el campo `ref`.

**Quién lo mantiene:** El Software Architect lo actualiza cuando crea o modifica un `ARCH-NNN` en `decisions.md`. El Tech Lead lo consulta antes de cada gate para evaluar impacto.

**Regla:** El grafo es un **índice de relaciones**, no una segunda fuente de verdad. Si hay divergencia, manda `decisions.md`.

**Documentación completa:** [`docs/knowledge-graph.md`](knowledge-graph.md)  
**Template:** [`templates/knowledge-graph.yaml`](../templates/knowledge-graph.yaml)

---

### `memory/` — Memoria Persistente del Pipeline

**Propósito:** Evitar que el contexto se pierda entre sesiones. Cada ejecución del pipeline deja una huella que los agentes futuros consumen automáticamente.

**Archivos:**

| Archivo | Tipo | Qué contiene |
|:---|:---|:---|
| `workflow-log.md` | Episódico | Log append-only de cada ejecución de agente |
| `decisions-catalog.md` | Semántico | Índice de decisiones vigentes con estado |
| `patterns-learned.md` | Procedimental | Patrones y lecciones reutilizables |
| `context-snapshot.md` | Compactado | Resumen ejecutivo para arrancar una sesión (~30 líneas) |

**Ciclo de vida:** `Capture → Compact → Recall`:
1. **Capture:** Cada agente, al terminar, escribe una entrada en `workflow-log.md`.
2. **Compact:** El Skill Manager regenera `context-snapshot.md` al iniciar cada sesión.
3. **Recall:** Los agentes leen el snapshot como parte de su contexto de activación.

**Regla de inferiencia:** La memoria es **contexto, no autoridad**. Los artefactos aprobados (`spec.md`, `architecture.md`) siguen siendo la fuente de verdad. La memoria ayuda a arrancar y a evitar repeticiones.

**Documentación completa:** [`docs/workflow-memory.md`](workflow-memory.md)

---

### `metrics/` — Métricas del Pipeline

**Propósito:** Rastrear tokens consumidos por rol, tiempo por fase y tasa de retry en cada ejecución, para detectar fases costosas y mejorar el sistema de agentes.

**Archivos:**

| Archivo | Propósito |
|:---|:---|
| `executions.yaml` | Registro append-only por ejecución (tokens, duración, fase, veredicto) |
| `agregados.yaml` | Agregados por fase/rol (regenerado por Skill Manager) |

**Métricas que se miden:** `tokens_in`, `tokens_out`, `duration_s`, `phase`, `attempts`, `veredicto`.

**Ciclo de vida:** `Capturar → Agregar → Decidir`:
1. **Capturar:** Cada agente registra su ejecución en `executions.yaml`.
2. **Agregar:** El Skill Manager regenera `agregados.yaml` al final de sesión.
3. **Decidir:** El Tech Lead revisa las métricas y ajusta el sistema (modos de ejecución, gates).

**Regla de inferiencia:** Las métricas **nunca** modifican artefactos ni versiones de agentes — son insumo para el Tech Lead, no autoridad.

**Documentación completa:** [`docs/agent-metrics.md`](agent-metrics.md)  
**Template:** [`templates/metrics-executions.yaml`](../templates/metrics-executions.yaml)

---

### `glossary.md`

**Propósito:** Diccionario de los términos del dominio con definiciones precisas y acordadas por el equipo y los stakeholders.

**Formato:**

```markdown
# Glosario — [Nombre del Proyecto]

## [Término]
**Definición:** [Qué significa este término en el contexto de este proyecto]  
**Sinónimos aceptados:** [Si los hay]  
**No confundir con:** [Si hay términos similares que se usan de forma diferente]  
**Usado en:** [Features, módulos o docs donde aparece]
```

**Cuándo actualizar:** Cuando un término nuevo aparece en el dominio, cuando se detecta ambigüedad o cuando un término cambia su significado acordado.

---

## Carpeta `features/`

**Propósito:** Contiene el trabajo activo de todas las features en progreso.

**Reglas:**
- Cada feature tiene su propia subcarpeta con el formato `FEAT-NNN-slug`
- Los documentos dentro de una feature **solo** hablan sobre esa feature
- Cuando una feature llega a producción, su carpeta se mueve a `archive/`
- Nunca crear documentos de feature fuera de esta carpeta

Ver [`templates/feature-folder-template.md`](../templates/feature-folder-template.md) para el contenido de cada feature.

---

## Carpeta `archive/`

**Propósito:** Almacena las iniciativas (features, bugs, auditorías, refactors) completadas y en producción como referencia histórica inmutable.

**Reglas:**
- Es **read-only** — ningún agente modifica archivos en `archive/`
- Se usa como referencia cuando se necesita entender cómo se construyó algo
- No es consumida como contexto activo por los agentes para evitar consumo innecesario de tokens
- Mantener el mismo nombre de carpeta que tenía en `features/`

**Cómo mover una iniciativa a archive:**
Se utiliza el script de automatización con Quality Gate:
```bash
# Archivar con validación de QA y actualización del Knowledge Graph
bash .ai/agents/scripts/archive-initiative.sh FEAT-XXX

# O en lote para todas las aprobadas
bash .ai/agents/scripts/sync-initiatives.sh --archive-approved
```

**Cuándo mover una feature a archive:**
- La feature pasó QA con veredicto `APROBADO` (o `PASS`)
- Fue aprobada por el Tech Lead tras validación en entorno de pruebas / staging
- El código está en producción (o en la rama principal)

---

## Carpeta `sessions/`

**Propósito:** Almacena conversaciones o sesiones de trabajo guardadas para referencia futura.

**Reglas:**
- Los archivos siguen el formato: `YYYY-MM-DD-descripcion.md`
- Son archivos de referencia, no documentos de trabajo
- Un agente puede guardar aquí el resumen de una sesión de trabajo compleja
- No deben contener decisiones — esas van a `decisions.md`

**Ejemplo de uso:**
```
sessions/
├── 2026-06-15-diseño-auth-module.md
└── 2026-06-22-refactor-payments.md
```

---

## Cómo inicializar `.ai/` en un proyecto nuevo

### Paso 1 — Crear la estructura de carpetas

```bash
mkdir -p .ai/features .ai/archive .ai/sessions
```

### Paso 2 — Crear los documentos permanentes

```bash
# Copiar los templates del repositorio ai-agents
cp ai-agents/templates/project-context.md .ai/context.md

# Crear los demás con contenido mínimo
touch .ai/business-rules.md
touch .ai/architecture.md
touch .ai/decisions.md
touch .ai/glossary.md
```

### Paso 3 — Completar `context.md`

Activar el agente Product Analyst con el template `project-context.md` para completar el contexto inicial del proyecto.

### Paso 4 — Integrar con el IDE

Agregar a `.cursorrules` o equivalente:

```markdown
Cuando trabajes en este proyecto:
1. Lee `.ai/context.md` para entender el proyecto
2. Lee `.ai/architecture.md` para entender la arquitectura actual
3. Consulta `.ai/business-rules.md` antes de definir comportamientos
4. Usa `.ai/features/FEAT-XXX/` para el trabajo de la feature actual
5. Nunca crees documentos fuera de `.ai/features/FEAT-XXX/` o actualices los permanentes sin verificar primero
```

---

## Integración con Git Submodules

```bash
# Agregar ai-agents como submodule
git submodule add https://github.com/ezequielmendoza-dev/abbia-os.git .ai/agents

# La estructura final del proyecto queda:
# .ai/
# ├── agents/     → submodule de ai-agents
# ├── context.md
# ├── ...
# └── features/
```

Ver [`docs/project-integration.md`](project-integration.md) para instrucciones completas de integración.

---

*Project AI Structure v2.0 — ai-agents framework | github.com/ezequielmendoza-dev/abbia-os*
