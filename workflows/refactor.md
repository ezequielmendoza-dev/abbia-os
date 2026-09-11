# Workflow: Refactor

> **Versión:** 1.0  
> **Agentes involucrados:** Tech Lead → Architect → Developer → QA

---

## Cuándo usar este workflow

- Hay deuda técnica identificada que impide trabajar con fluidez
- Un módulo necesita ser reestructurado sin cambiar su comportamiento externo
- Se detectó una violación de arquitectura que debe corregirse
- El Tech Lead detectó un problema de mantenibilidad durante una revisión

---

## Principio Fundamental

> Un refactor **no cambia el comportamiento observable del sistema**.  
> Si cambia algo visible para el usuario o para otras APIs → es una feature o un bug fix, no un refactor.

---

## Flujo

```mermaid
flowchart TD
    A[🔧 Necesidad de refactor identificada] --> B[Tech Lead: Evaluar alcance y riesgo]
    B --> C{¿El refactor cambia la arquitectura global?}
    C -->|Sí| D[🏗️ Architect: Rediseñar el componente]
    C -->|No| E[💻 Developer: Refactorizar]
    D --> F[Tech Lead: Revisar nuevo diseño]
    F -->|Rechazado| D
    F -->|Aprobado| E
    E --> G[🧪 QA: Verificar que no hay regresiones]
    G --> H{¿Regresiones encontradas?}
    H -->|Sí| E
    H -->|No| I[Tech Lead: Veredicto final]
    I --> J[🚀 Deploy]
    J --> K[📝 Actualizar .ai/architecture.md si aplica]
```

---

<!-- dag:start -->
**Modos de ejecución:** `rápido` | `estándar` (default) | `profundo` (ver `docs/workflow-dag.md`)

```yaml
name: refactor
modes:
  rapido:
    truncate: [architect-design]
    note: Para refactors locales de un módulo sin impacto global
  estandar: {}
  profundo:
    extra: [adversarial-review]
    note: Para refactors de alto riesgo o globales
nodes:
  evaluate-refactor:
    agent: tech-lead
    input: [context.md, architecture.md, decisions.md]
    output: [decisión de alcance]
    gate: true
  architect-design:
    agent: architect
    input: [decisions.md, architecture.md]
    output: [diseño post-refactor]
    parallel: false
  tech-review-design:
    agent: tech-lead
    input: [diseño post-refactor]
    output: [verdict]
    gate: true
  implement-refactor:
    agent: developer
    input: [diseño post-refactor (o decisión)]
    parallel: true       # fan-out por módulo si el Tech Lead los declara independientes
  qa-regression:
    agent: qa
    input: [código refactorizado]
    output: [qa.md]
    parallel: false
  tech-review-final:
    agent: tech-lead
    input: [qa.md]
    output: [verdict]
    gate: true
  deploy:
    agent: devops
    input: [código]
    output: [release]
    parallel: false
  adversarial-review:
    agent: qa
    input: [código refactorizado, arquitectura previa]
    output: [adversarial-review.md]
    parallel: false
edges:
  - { from: evaluate-refactor,  to: architect-design, on: "ARQUITECTURA_GLOBAL" }
  - { from: evaluate-refactor,  to: implement-refactor, on: "LOCAL" }
  - { from: architect-design,   to: tech-review-design }
  - { from: tech-review-design, to: implement-refactor, on: APROBADO }
  - { from: tech-review-design, to: architect-design,   on: RECHAZADO, retry: 1, back: true }
  - { from: implement-refactor, to: qa-regression,      type: fan-in }
  - { from: qa-regression,      to: tech-review-final }
  - { from: qa-regression,      to: implement-refactor, on: REGRESION, retry: 1, back: true }
  - { from: tech-review-final,  to: deploy,             on: APROBADO }
  - { from: tech-review-final,  to: implement-refactor, on: RECHAZADO, retry: 1, back: true }
  - { from: tech-review-final,  to: adversarial-review, type: fan-out }   # solo profundo
  - { from: adversarial-review, to: deploy,             on: PASS, type: fan-in }
hotfix:
  enabled: false
```
<!-- dag:end -->

---

## Pasos Detallados

### Paso 0 — Evaluación de Necesidad (Tech Lead)

Antes de aprobar cualquier refactor, el Tech Lead debe responder:

1. **¿Cuál es el problema concreto?** (no "el código está feo", sino "el módulo X tiene N responsabilidades que dificultan Y")
2. **¿Cuál es el beneficio esperado?** (mantenibilidad, performance, testabilidad)
3. **¿Cuál es el riesgo?** (qué puede romperse, qué tests existen)
4. **¿Es el momento correcto?** (¿hay features activas en el mismo módulo?)
5. **¿Cambia algo visible externamente?** Si sí → no es un refactor puro

**Leer antes de decidir:**
- `.ai/context.md` — convenciones del proyecto
- `.ai/architecture.md` — arquitectura actual
- `.ai/decisions.md` — por qué está diseñado así

---

### Paso 1 — Diseño del Refactor (Architect, si aplica)

Solo necesario si el refactor cambia la arquitectura global del sistema.

**Agente:** Software Architect  
**Activación:**

```
Actúa como el agente Software Architect definido en roles/architect.md.

Contexto del proyecto: [contenido de .ai/context.md]
Arquitectura actual: [contenido de .ai/architecture.md]

Necesito diseñar un refactor del siguiente componente:
[nombre del componente y descripción del problema actual]

El refactor NO debe cambiar el comportamiento externo del sistema.
Objetivo: [objetivo del refactor]
```

**Output:** Diseño del estado post-refactor con la lista de cambios y el orden de implementación.

Si el resultado cambia `architecture.md` → actualizar como parte de este paso.

---

### Paso 2 — Revisión del Diseño (Tech Lead)

Si el Architect diseñó el refactor, el Tech Lead lo revisa antes de implementar.

**Verificar:**
- El refactor resuelve el problema identificado
- No introduce complejidad innecesaria
- No cambia el comportamiento externo
- El orden de implementación es correcto y seguro

---

### Paso 3 — Implementación (Developer)

**Agente:** Senior Developer  
**Activación:**

```
Actúa como el agente Senior Developer definido en roles/developer.md.

Contexto del proyecto: [contenido de .ai/context.md]

Refactor a implementar:
[descripción del refactor aprobado]

Restricción crítica: el comportamiento externo del sistema NO debe cambiar.

Componente afectado:
[nombre del módulo/archivo/función]
```

**Reglas de implementación:**
- Hacer el refactor en pasos pequeños y verificables, no en un único commit gigante
- Mantener los tests existentes — si los tests fallan, es un bug, no un refactor
- Si durante el refactor se detecta un bug → documentarlo y abrir un `BUG-NNN` separado. No corregirlo en el mismo PR.
- Documentar qué cambió y por qué para que QA pueda entender el alcance

---

### Paso 4 — Validación de Regresiones (QA)

**Agente:** QA Engineer  
**Objetivo:** Verificar que el refactor no rompió ningún comportamiento existente.

**Activación:**

```
Actúa como el agente QA Engineer definido en roles/qa.md.

Contexto del proyecto: [contenido de .ai/context.md]

Estoy validando un refactor del componente: [nombre]

El refactor NO debe cambiar el comportamiento externo del sistema.

Cambios realizados:
[descripción de los cambios del Developer]

Por favor, verifica que todos los comportamientos existentes siguen funcionando correctamente.
```

**Criterio de éxito:** Todos los criterios de aceptación previamente existentes siguen cumpliéndose. No se abrieron bugs nuevos.

---

### Paso 5 — Cierre del Refactor

1. **Actualizar CHANGELOG:** Registrar el cambio en `[Unreleased]` bajo `### Changed` directamente en `CHANGELOG.md`.
2. **Version Bump y Commit:** Una vez aprobado por el Tech Lead, ejecutar `npm run bump:patch -- "refactor(scope): descripción"` para actualizar versión (patch), mover el unreleased a la nueva versión, y crear git tag.
3. **Deploy** (ver [`workflows/release.md`](release.md))
4. **Actualizar** `.ai/architecture.md` si el refactor cambió algo en la arquitectura global
5. **Registrar** en `.ai/decisions.md` si el refactor implicó una decisión técnica importante

---

## Checklist de Refactor

- [ ] Problema a resolver identificado con precisión
- [ ] Tech Lead aprobó que es necesario y el momento es correcto
- [ ] Architect diseñó el cambio (si afecta arquitectura global)
- [ ] Implementación en pasos pequeños y verificables
- [ ] Tests existentes pasan sin modificaciones (si fallan, hay un bug)
- [ ] QA confirmó ausencia de regresiones
- [ ] Veredicto del Tech Lead: `APROBADO`
- [ ] `CHANGELOG.md` actualizado
- [ ] Versión bumpeda (`npm run bump:patch`)
- [ ] Git tag `vX.Y.Z` creado y pusheado
- [ ] Deploy realizado
- [ ] `architecture.md` actualizado si fue necesario
- [ ] `decisions.md` actualizado si hubo una decisión técnica relevante

---

## Anti-patrones de refactor

| Anti-patrón | Problema | Alternativa |
|------------|---------|-------------|
| "Refactorizar y agregar la feature al mismo tiempo" | Mezcla dos tipos de cambio, hace difícil el debugging | Dos PRs separados: primero el refactor, luego la feature |
| "El refactor está casi listo, cambio rápido esta regla de negocio" | Ya no es un refactor | Parar, crear un BUG o FEAT separado |
| "El refactor es tan grande que no puedo separarlo" | El alcance es demasiado amplio | Dividir en múltiples refactors pequeños y secuenciales |
| "Vamos a refactorizar todo antes de la siguiente feature" | Big-bang refactor de alto riesgo | Refactorizar solo lo necesario para que la feature entre bien |

---

*Workflow refactor v1.0 — ai-agents library | github.com/ezequielmendoza-dev/ai-agents*
