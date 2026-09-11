# Workflow: Nueva Feature

> **Versión:** 2.0  
> **Agentes involucrados:** Analyst → UI Designer → Architect → Tech Lead → Developer → QA → DevOps (si aplica)

---

## Cuándo usar este workflow

- Se solicita implementar una funcionalidad nueva
- La feature no existe en ninguna forma en el sistema
- Hay un requerimiento del stakeholder que necesita especificarse y construirse

---

## Flujo

```mermaid
flowchart TD
    A[💡 Requerimiento del stakeholder] --> B[Verificar .ai/context.md y business-rules.md]
    B --> C[🔍 Analyst: Discovery]
    C --> D{Ambigüedades críticas?}
    D -->|Sí| E[📝 discovery.md]
    D -->|No| F[📝 spec.md]
    E --> F
    F --> G{Tech Lead: Revisar spec}
    G -->|Rechazado| F
    G -->|Aprobado| UI[🎨 UI Designer: Crear ui-design.md en FEAT-XXX]
    UI --> H[🏗️ Architect: Crear architecture.md en FEAT-XXX]
    H --> I{Tech Lead: Revisar diseño visual y técnico}
    I -->|Rechazado UI| UI
    I -->|Rechazado Técnico| H
    I -->|Aprobado| J[💻 Developer: Implementar]
    J --> K[🧪 QA: Crear qa.md en FEAT-XXX]
    K --> L{Resultado QA}
    L -->|FAIL| J
    L -->|PASS / PASS WITH OBS| M{Tech Lead: Veredicto final}
    M -->|Rechazado| J
    M -->|Aprobado| Ask[💬 Preguntar Commit, Push y Release]
    Ask --> N[🚀 DevOps: Deployment]
    N --> O[📁 Mover FEAT-XXX a archive/]
    O --> P[📝 Actualizar docs permanentes si aplica]
```

---

<!-- dag:start -->
**Modos de ejecución:** `rápido` | `estándar` | `profundo` (ver `docs/workflow-dag.md`)

```yaml
name: new-feature
modes:
  rapido:
    truncate: [discovery, ui-design, architecture]
    note: Para bugs bien definidos o cambios de bajo riesgo en features existentes
  estandar: {}
  profundo:
    extra: [adversarial-review]
    note: Para features críticas o arquitectónicas
nodes:
  discovery:
    agent: analyst
    input: [context.md, feature-request]
    output: [discovery.md]
    parallel: false
  spec:
    agent: analyst
    input: [context.md, discovery.md (opcional)]
    output: [spec.md]
    parallel: false
  tech-review-1:
    agent: tech-lead
    input: [spec.md]
    output: [verdict]
    gate: true
  ui-design:
    agent: ui-designer
    input: [spec.md, context.md]
    output: [ui-design.md]
    parallel: false
  architecture:
    agent: architect
    input: [spec.md, ui-design.md, context.md, architecture.md]
    output: [architecture.md]
    parallel: false
  tech-review-2:
    agent: tech-lead
    input: [spec.md, ui-design.md, architecture.md]
    output: [verdict]
    gate: true
  implement:
    agent: developer
    input: [task.md, spec.md, ui-design.md, architecture.md]
    parallel: true
  qa:
    agent: qa
    input: [spec.md, ui-design.md, architecture.md, code]
    output: [qa.md]
    parallel: false
  tech-review-3:
    agent: tech-lead
    input: [qa.md]
    output: [verdict]
    gate: true
  deploy:
    agent: devops
    input: [architecture.md]
    output: [release]
    parallel: false
  adversarial-review:
    agent: qa
    input: [spec.md, architecture.md, code]
    output: [adversarial-review.md]
    parallel: false
edges:
  - { from: discovery,      to: spec }
  - { from: spec,           to: tech-review-1 }
  - { from: tech-review-1,  to: ui-design,     on: APROBADO }
  - { from: tech-review-1,  to: spec,          on: RECHAZADO, retry: 1, back: true }
  - { from: ui-design,      to: architecture }
  - { from: architecture,   to: tech-review-2 }
  - { from: tech-review-2,  to: implement,     on: APROBADO }
  - { from: tech-review-2,  to: ui-design,     on: RECHAZADO_UI,       retry: 1, back: true }
  - { from: tech-review-2,  to: architecture,  on: RECHAZADO_TECNICO,  retry: 1, back: true }
  - { from: implement,      to: qa }
  - { from: qa,             to: tech-review-3 }
  - { from: qa,             to: implement,     on: FAIL, retry: 1, back: true }
  - { from: tech-review-3,  to: deploy,        on: PASS }
  - { from: tech-review-3,  to: implement,     on: FAIL, retry: 1, back: true }
  - { from: tech-review-3,  to: adversarial-review, type: fan-out }   # solo en modo profundo
  - { from: adversarial-review, to: deploy,    on: PASS, type: fan-in }
hotfix:
  enabled: false
```
<!-- dag:end -->

---

## Pasos Detallados

### Paso 0 — Preparación

Antes de iniciar cualquier trabajo:

1. Leer `.ai/context.md` para entender el sistema actual
2. Leer `.ai/business-rules.md` para conocer las restricciones de negocio
3. Leer `.ai/architecture.md` para entender la arquitectura vigente
4. Consultar `.ai/decisions.md` para conocer decisiones relevantes anteriores
5. **Asignar el ID de la feature** consultando el Registro de IDs en `context.md`
6. Crear la carpeta `.ai/features/FEAT-NNN-slug/`

```bash
mkdir -p .ai/features/FEAT-NNN-slug
touch .ai/features/FEAT-NNN-slug/discovery.md # Opcional, solo si hay ambigüedades
touch .ai/features/FEAT-NNN-slug/spec.md
touch .ai/features/FEAT-NNN-slug/ui-design.md
touch .ai/features/FEAT-NNN-slug/architecture.md
touch .ai/features/FEAT-NNN-slug/qa.md
touch .ai/features/FEAT-NNN-slug/decision.md
```

7. Actualizar el Registro de IDs en `.ai/context.md`

---

### Paso 0.5 — Discovery (Analyst - Opcional)

**Agente:** Product Analyst  
**Output:** `.ai/features/FEAT-NNN-slug/discovery.md`  
**Template:** [`templates/discovery.md`](../templates/discovery.md)

**Activación:** Ocurre automáticamente en la evaluación del Analyst. Si detecta ambigüedades críticas, interrumpe el flujo normal y produce este documento en lugar de la spec.

**Criterio de salida:** `discovery.md` publicado. Se requiere respuesta del stakeholder para continuar.

---

### Paso 1 — Especificación Funcional (Analyst)

**Agente:** Product Analyst  
**Output:** `.ai/features/FEAT-NNN-slug/spec.md`  
**Template:** [`templates/feature-spec.md`](../templates/feature-spec.md)

**Activación:**

```
Actúa como el agente Product Analyst definido en roles/analyst.md.

Contexto del proyecto: [contenido de .ai/context.md]
Reglas de negocio: [contenido de .ai/business-rules.md]

Feature a especificar: FEAT-NNN — [nombre]

Requerimiento:
[descripción del requerimiento]
```

**Criterio de salida:** `spec.md` completa, sin preguntas abiertas bloqueantes, lista para revisión del Tech Lead.

---

### Paso 2 — Revisión de Especificación (Tech Lead)

**Agente:** Tech Lead  
**Veredictos posibles:** APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO

Si es **RECHAZADO** → volver al Paso 1 con el feedback del Tech Lead.  
Si es **APROBADO** → continuar al Paso 3.

**Activación:**

```
Actúa como el agente Tech Lead definido en roles/tech-lead.md.

Contexto del proyecto: [contenido de .ai/context.md]

Estoy presentando para revisión: feature-spec
### Paso 3 — Diseño de Interfaz (UI Designer)

**Agente:** UI Designer  
**Output:** `.ai/features/FEAT-NNN-slug/ui-design.md`  
**Template:** [`templates/ui-design-spec.md`](../templates/ui-design-spec.md)

**Activación:**

```
Actúa como el agente UI Designer definido en roles/ui-designer.md.

Contexto del proyecto: [contenido de .ai/context.md]

Especificación funcional de referencia:
[contenido de .ai/features/FEAT-NNN-slug/spec.md]
```

**Criterio de salida:** `ui-design.md` completa, con la arquitectura de información, layouts y componentes diseñados para todos los viewports, lista para el desarrollo.

---

### Paso 4 — Diseño Técnico (Architect)

**Agente:** Software Architect  
**Output:** `.ai/features/FEAT-NNN-slug/architecture.md`  
**Template:** [`templates/architecture-spec.md`](../templates/architecture-spec.md)

Si el diseño requiere cambios en la arquitectura global, actualizar `.ai/architecture.md` en este paso.

**Activación:**

```
Actúa como el agente Software Architect definido en roles/architect.md.

Contexto del proyecto: [contenido de .ai/context.md]
Arquitectura actual: [contenido de .ai/architecture.md]

Especificación funcional a diseñar:
[contenido de .ai/features/FEAT-NNN-slug/spec.md]

Diseño visual de referencia:
[contenido de .ai/features/FEAT-NNN-slug/ui-design.md]
```

---

### Paso 5 — Revisión de Diseño (Tech Lead)

**Agente:** Tech Lead  
**Veredictos posibles:** APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO

Si es **RECHAZADO** (por diseño técnico o visual) → volver al Paso 3 o 4 con el feedback del Tech Lead.  
Si hay decisiones de arquitectura importantes → registrar en `.ai/decisions.md`.  
Si es **APROBADO** → continuar al Paso 6.

---

### Paso 6 — Implementación (Developer)

**Agente:** Senior Developer  
**Template de referencia:** [`templates/technical-task.md`](../templates/technical-task.md)

**Activación:**

```
Actúa como el agente Senior Developer definido en roles/developer.md.

Contexto del proyecto: [contenido de .ai/context.md]

Tarea a implementar:
[descripción de la tarea técnica]

Especificación de referencia:
[contenido de .ai/features/FEAT-NNN-slug/spec.md]

Diseño visual de referencia:
[contenido de .ai/features/FEAT-NNN-slug/ui-design.md]

Diseño técnico de referencia:
[contenido de .ai/features/FEAT-NNN-slug/architecture.md]
```

**Criterio de salida:** Implementación completa, funcional y fiel a la UI y la arquitectura, lista para QA.

---

### Paso 7 — Validación de Calidad (QA)

**Agente:** QA Engineer  
**Output:** `.ai/features/FEAT-NNN-slug/qa.md`  
**Template:** [`templates/qa-report.md`](../templates/qa-report.md)

**Activación:**

```
Actúa como el agente QA Engineer definido en roles/qa.md.

Contexto del proyecto: [contenido de .ai/context.md]

Feature spec de referencia:
[contenido de .ai/features/FEAT-NNN-slug/spec.md]

Diseño visual de referencia:
[contenido de .ai/features/FEAT-NNN-slug/ui-design.md]

Diseño técnico de referencia:
[contenido de .ai/features/FEAT-NNN-slug/architecture.md]

Implementación a revisar:
[descripción de los cambios implementados]
```

Si el resultado es **FAIL** → volver al Paso 6 con los bugs reportados.  
Si el resultado es **PASS** o **PASS WITH OBSERVATIONS** → continuar al Paso 8.

---

### Paso 8 — Final Veredicto (Tech Lead)

**Agente:** Tech Lead  
**Acción:** Revisar el reporte de QA y emitir veredicto final de deployment.

**Interacción Interactiva (Commit, Push y Release):**
> [!IMPORTANT]
> Una vez que el Tech Lead apruebe la feature, la IA **debe guiar activamente al usuario** en:
> 1. **Commit y Push:** Proponer un mensaje de commit que siga rigorousamente las convenciones (ej. `feat(scope): FEAT-NNN - descripcion`). Preguntar al usuario si desea proceder.
> 2. **Version Bump:** Una vez hecho el commit, ejecutar `npm run bump:minor -- "FEAT-NNN: descripción"` para actualizar la versión (minor), el CHANGELOG y el context. Esto mueve los cambios de `[Unreleased]` a la nueva versión.
> 3. **Git Tag:** Crear tag `git tag -a vX.Y.Z -m "FEAT-NNN: descripción"` y push con `git push --tags`.
> 4. **Release:** Indicar al usuario si debe proceder con release según [`workflows/release.md`](release.md).

---

### Paso 9 — Deployment (DevOps)

**Agente:** DevOps Engineer (bajo demanda del Tech Lead)  
**Workflow:** Ver [`workflows/release.md`](release.md) para el proceso de deployment.

---

### Paso 10 — Cierre de Feature

Cuando la feature está en producción:

1. **Mover** la carpeta al archivo histórico:
   ```bash
   mv .ai/features/FEAT-NNN-slug .ai/archive/FEAT-NNN-slug
   ```

2. **Actualizar** los documentos permanentes si la feature cambió algo global:
   - `.ai/architecture.md` si cambió la arquitectura del sistema
   - `.ai/business-rules.md` si se incorporaron nuevas reglas permanentes
   - `.ai/glossary.md` si aparecieron nuevos términos del dominio
   - `.ai/decisions.md` si hay decisiones que aplican globalmente

3. **Actualizar** el `CHANGELOG.md` del proyecto con la feature completada (esto ya se hizo automáticamente en el Paso 8 con `npm run bump:minor`).

---

## Checklist de Cierre de Feature

- [ ] `spec.md` en estado `Aprobada`
- [ ] `ui-design.md` en estado `Aprobado`
- [ ] `architecture.md` en estado `Aprobado`
- [ ] `qa.md` en estado `PASS` o `PASS WITH OBSERVATIONS` resueltas
- [ ] Veredicto del Tech Lead: `APROBADO`
- [ ] Código en rama principal / producción
- [ ] Documentos permanentes actualizados si fue necesario
- [ ] Feature movida a `archive/`
- [ ] `CHANGELOG.md` actualizado
- [ ] Versión bumpeda (`npm run bump:minor`)
- [ ] Git tag `vX.Y.Z` creado y pusheado

---

*Workflow Nueva Feature v2.0 — ai-agents framework | github.com/ezequielmendoza-dev/ai-agents*
