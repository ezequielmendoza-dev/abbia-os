# Estrategia Documental — ai-agents

> **Versión:** 2.0  
> **Estado:** Vigente  
> **Última actualización:** Julio 2026

---

## Filosofía

Este sistema opera bajo dos principios centrales:

> **Los documentos son la fuente de verdad. Los agentes son transformadores de conocimiento.**

> **Un documento existente actualizado siempre vale más que un documento nuevo.**

El conocimiento no crece creando archivos. Crece manteniendo una única fuente de verdad, actualizada, sin duplicación y sin ruido.

Los agentes de `ai-agents` no son generadores de documentos. Son **transformadores de conocimiento** que producen artefactos verificables.

Ver [`docs/sdd-philosophy.md`](sdd-philosophy.md) para el modelo mental completo del framework.

### Los tres problemas que esta estrategia resuelve

| Problema | Síntoma | Causa raíz |
|----------|---------|------------|
| Crecimiento descontrolado | Decenas de archivos `architecture-v2.md`, `arch-final.md` | No hay regla que obligue a actualizar en lugar de crear |
| Información obsoleta | Decisiones de 6 meses atrás tomadas como vigentes | No hay ciclo de vida ni señal de que un doc fue superado |
| Ruido para la IA | El modelo consume contexto irrelevante o contradictorio | No hay separación entre conocimiento permanente y trabajo temporal |

---

## Dos tipos de conocimiento

### A. Conocimiento Permanente

Representa el **estado actual del sistema**. Vive en `.ai/` en la raíz del proyecto.

Características:
- Siempre hay **una sola versión vigente**
- Se actualiza en el lugar — nunca se crea una copia
- No tiene timestamp en el nombre del archivo
- Cualquier agente puede leerlo como fuente de verdad
- Si está desactualizado, es un problema a corregir de inmediato

Archivos permanentes estándar:

```
.ai/
├── context.md          # Identidad del proyecto: qué es, stack, equipo, convenciones
├── business-rules.md   # Reglas de negocio del dominio (no técnicas)
├── architecture.md     # Arquitectura actual del sistema (estado real, no aspiracional)
├── decisions.md        # Log de decisiones arquitectónicas importantes (append-only)
└── glossary.md         # Términos del dominio con definiciones precisas y acordadas
```

### B. Trabajo por Feature

Cada iniciativa de trabajo tiene su propio espacio aislado. Vive en `.ai/features/`.

Características:
- Completamente independiente de otras features
- Tiene un identificador único (`FEAT-XXX`)
- Contiene solo información relevante a esa iniciativa
- Cuando la feature termina, se mueve a `archive/` (read-only)
- Los documentos dentro de una feature **sí pueden tener múltiples iteraciones** (spec v1, spec v2), pero como actualizaciones del mismo archivo — no como archivos nuevos

```
.ai/features/
├── FEAT-001-seat-layout/
│   ├── spec.md
│   ├── architecture.md
│   ├── qa.md
│   └── decision.md
└── FEAT-002-user-notifications/
    └── ...
```

---

## Convenciones

### Regla 1 — Verificar antes de crear

Antes de crear cualquier documento, el agente debe responder:

> ¿Existe algún documento en `.ai/` o en `.ai/features/FEAT-XXX/` que debería actualizarse en lugar de crearse uno nuevo?

Si la respuesta es sí → **actualizar**.  
Si la respuesta es no → crear con el nombre correcto siguiendo las convenciones.

---

### Regla 2 — Actualización > Creación

Cuando una feature modifica la arquitectura global del sistema:

- ❌ No crear `architecture-updated.md`
- ✅ Actualizar `.ai/architecture.md` directamente

Cuando una decisión técnica importante se toma:

- ❌ No crear `decision-auth-2026.md`
- ✅ Agregar una entrada nueva en `.ai/decisions.md`

---

### Regla 3 — Prohibición de versiones en nombres de archivos

Los siguientes patrones de nombre de archivo están **estrictamente prohibidos**:

```
architecture-v2.md       ❌
architecture-final.md    ❌
architecture-review.md   ❌
spec-updated.md          ❌
context-new.md           ❌
decisions-2026.md        ❌
```

Si un agente siente la necesidad de crear uno de estos archivos, es una señal de que debe actualizar el documento existente y registrar el cambio en `CHANGELOG.md` del proyecto o en `decisions.md`.

---

### Regla 4 — Documentos específicos solo en features

Ningún documento específico de una iniciativa debe existir fuera de su carpeta de feature.

- ❌ `.ai/feature-reservas-spec.md`
- ✅ `.ai/features/FEAT-001-reservas/spec.md`

---

### Regla 5 — Los documentos raíz = estado actual

Los documentos en `.ai/` representan el sistema **hoy**, no el sistema en algún momento histórico.

Si `architecture.md` describe algo que ya no es verdad, es un documento incorrecto — no un documento histórico válido. Debe corregirse.

---

## Flujo de actualización

### Cuándo actualizar `.ai/context.md`
- Se incorpora un nuevo servicio o dependencia crítica
- Cambia el stack tecnológico principal
- Hay un cambio de equipo o de convenciones de código

### Cuándo actualizar `.ai/business-rules.md`
- El Analyst identifica una nueva regla de negocio permanente
- Una regla existente cambia por decisión del negocio
- Se detecta una inconsistencia entre reglas

### Cuándo actualizar `.ai/architecture.md`
- El Architect diseña un cambio estructural aprobado por el Tech Lead
- Un módulo nuevo entra en producción
- Una decisión de `decisions.md` impacta el diseño global

### Cuándo agregar a `.ai/decisions.md`
- Se toma una decisión técnica no obvia con alternativas descartadas
- Se adopta un nuevo patrón arquitectónico
- Se decide romper con una convención anterior (con justificación)

### Cuándo actualizar `.ai/glossary.md`
- Aparece un término nuevo en el dominio
- Un término existente cambia su significado
- Se detecta ambigüedad en el uso de un término

---

## Ciclo de vida de documentos

### Documentos de feature

```
CREACIÓN         → Al iniciar la feature (FEAT-XXX creado)
DESARROLLO       → Actualizaciones en el lugar durante el trabajo
COMPLETADA       → Feature en producción, docs movidos a archive/
ARCHIVADA        → Read-only, referencia histórica únicamente
```

### Documentos permanentes

```
CREACIÓN         → Una sola vez, al inicializar el proyecto
VIGENTE          → Estado normal — se actualiza cuando cambia la realidad
DESACTUALIZADO   → Estado de error — debe corregirse antes de continuar trabajando
```

### Señales de que un documento está desactualizado

- Describe tecnologías que ya no se usan
- Menciona features que aún no existen o que ya fueron reemplazadas
- Contradice el código en producción
- Fue creado hace más de 3 meses sin ninguna actualización en un proyecto activo

---

## Estados de los Artefactos de Feature

Cada artefacto de una feature tiene un ciclo de vida explícito. El estado se registra en el campo `Estado` del metadata de cada documento.

### `discovery.md`

```
ACTIVO     → Durante la sesión de discovery
COMPLETO   → Cuando spec.md fue producida a partir de él
```

### `spec.md`

```
Draft           → Analyst lo produjo, pendiente de revisión
Reviewed        → Tech Lead revisó con observaciones
Approved        → Tech Lead aprobó, ningún agente puede modificarlo sin aprobación
```

### `ui-design.md` y `architecture.md`

```
Draft           → Producido por el agente responsable
Reviewed        → Tech Lead revisó con observaciones
Approved        → Tech Lead aprobó
```

### `qa.md`

```
Open            → QA en progreso
Pass            → Sin bugs críticos
Pass with Obs.  → Bugs menores, Tech Lead decide
Fail            → Bugs críticos, Developer debe corregir
```

### Ciclo de vida de la feature (campo `Estado` en `spec.md`)

```
Discovery → Draft → Reviewed → Approved → In Progress → Done → Archived
```

Ver [`docs/artifact-lifecycle.md`](artifact-lifecycle.md) para la referencia completa de estados, transiciones y responsables.

---

## Anti-patrones a evitar

| Anti-patrón | Por qué es un problema | Alternativa correcta |
|------------|----------------------|---------------------|
| Crear `architecture-v2.md` | Duplica conocimiento, confunde sobre cuál es la versión vigente | Actualizar `architecture.md` |
| Crear docs en `/docs` del proyecto desde agentes | Genera ruido, no hay gobernanza | Usar `.ai/features/FEAT-XXX/` o actualizar docs permanentes |
| Documentar decisiones dentro de una feature-spec | La spec documenta *qué*, no *por qué se decidió así* | Usar `decision.md` dentro de la feature |
| Dejar features activas en `features/` cuando ya están en producción | Ocupa espacio semántico, confunde el estado actual | Mover a `archive/` al cerrar la feature |
| Crear un nuevo `context.md` cuando cambia algo | El contexto debe estar siempre actualizado | Actualizar `context.md` directamente |

---

## Integración con agentes

Todos los agentes de `ai-agents` deben:

1. **Leer** `.ai/context.md` como primer paso antes de operar
2. **Consultar** el documento relevante de `.ai/` antes de cualquier decisión
3. **Actualizar** documentos permanentes cuando su output cambia la realidad del sistema
4. **Crear** documentos de feature únicamente dentro de `.ai/features/FEAT-XXX/`
5. **Registrar** decisiones no triviales en `.ai/decisions.md`

Ver [`docs/project-ai-structure.md`](project-ai-structure.md) para la estructura completa recomendada.

Ver [`docs/artifact-lifecycle.md`](artifact-lifecycle.md) para el ciclo de vida de los artefactos.

---

*Estrategia documental v2.0 — ai-agents framework | github.com/ezequielmendoza-dev/abbia-os*
