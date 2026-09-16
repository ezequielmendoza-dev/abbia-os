# Workflow: Corrección de Bugs (Bug Fix)

> **Versión:** 2.0  
> **Agentes involucrados:** Dinámico según clasificación (QA, Analyst, UI Designer, Architect, Developer, Tech Lead, DevOps)

---

## Cuándo usar este workflow

- Se detecta un comportamiento anómalo o incorrecto en producción, staging o desarrollo.
- Un usuario, stakeholder o QA reporta un defecto de interfaz, lógica de negocio, arquitectura técnica o rendimiento.

---

## Flujo Dinámico del Pipeline

```mermaid
flowchart TD
    Start[🐛 Bug Detectado] --> Triaje[Paso 0: Triaje y Clasificación]
    
    Triaje --> Categorias{Categoría del Bug}
    
    Categorias -->|1. Negocio / Funcional| Spec[Paso 1.A: Ajuste de Spec - Analyst]
    Spec --> TL_Spec{Revisión TL}
    TL_Spec -->|Rechazado| Spec
    TL_Spec -->|Aprobado| Dev
    
    Categorias -->|2. Visual / UI-UX| UI[Paso 1.B: Ajuste de Interfaz - UI Designer]
    UI --> Dev
    
    Categorias -->|3. Arquitectura / Técnico| Tech[Paso 1.C: Ajuste Técnico - Architect]
    Tech --> TL_Arch{Revisión TL}
    TL_Arch -->|Rechazado| Tech
    TL_Arch -->|Aprobado| Dev
    
    Categorias -->|4. Implementación Pura| Dev[Paso 2: Corrección - Developer]
    
    Categorias -->|5. Crítico / Hotfix| Hot[Paso Especial: Hotfix Directo]
    Hot --> Dev
    
    Dev --> QA[Paso 3: Validación - QA]
    QA --> QA_Status{¿Bug Resuelto?}
    QA_Status -->|No| Dev
    QA_Status -->|Sí| TL_Final{Paso 4: Veredicto Final - Tech Lead}
    
    TL_Final -->|Aprobado| Ask[💬 Preguntar Commit, Push y Release]
    TL_Final -->|Rechazado| Dev
    
    Ask --> Deploy[Paso 5: Deploy y Cierre]
```

---

<!-- dag:start -->
**Modos de ejecución:** `rápido` (default para bugs) | `estándar` | `profundo` (ver `docs/workflow-dag.md`)

```yaml
name: bug-fix
modes:
  rapido:
    note: Default para bugs — el sub-DAG se selecciona por categoría en el triaje
  estandar: {}
  profundo:
    extra: [adversarial-review]
nodes:
  bug-triage:
    agent: tech-lead
    input: [bug-report.md, context.md]
    output: [clasificación]
    gate: true
  spec-fix:
    agent: analyst
    input: [bug-report.md, spec.md (existente)]
    output: [spec.md (actualizada)]
    parallel: false
  ui-fix:
    agent: ui-designer
    input: [bug-report.md, ui-design.md (existente)]
    output: [ui-design.md (actualizado)]
    parallel: false
  architecture-fix:
    agent: architect
    input: [bug-report.md, architecture.md (existente)]
    output: [architecture.md (actualizado)]
    parallel: false
  tech-review-fix:
    agent: tech-lead
    input: [spec.md o architecture.md (según categoría)]
    output: [verdict]
    gate: true
  implement-fix:
    agent: developer
    input: [bug-report.md, documentos corregidos]
    parallel: false
  qa-fix:
    agent: qa
    input: [bug-report.md, código]
    output: [qa.md]
    parallel: false
  tech-review-final:
    agent: tech-lead
    input: [qa.md]
    output: [verdict]
    gate: true
  hotfix-deploy:
    agent: devops
    input: [código]
    output: [release directo]
    parallel: false
  deploy:
    agent: devops
    input: [bug-report.md]
    output: [release]
    parallel: false
  adversarial-review:
    agent: qa
    input: [bug-report.md, código]
    output: [adversarial-review.md]
    parallel: false
edges:
  # Sub-DAG 1: Negocio
  - { from: bug-triage, to: spec-fix,           on: "Categoria: Negocio" }
  - { from: spec-fix,   to: tech-review-fix }
  - { from: tech-review-fix, to: implement-fix, on: APROBADO }
  - { from: tech-review-fix, to: spec-fix,      on: RECHAZADO, retry: 1, back: true }
  # Sub-DAG 2: Visual
  - { from: bug-triage, to: ui-fix,             on: "Categoria: Visual" }
  - { from: ui-fix,     to: implement-fix }
  # Sub-DAG 3: Arquitectura
  - { from: bug-triage, to: architecture-fix,   on: "Categoria: Arquitectura" }
  - { from: architecture-fix, to: tech-review-fix }
  - { from: tech-review-fix, to: implement-fix, on: APROBADO }
  - { from: tech-review-fix, to: architecture-fix, on: RECHAZADO, retry: 1, back: true }
  # Sub-DAG 4: Implementación pura
  - { from: bug-triage, to: implement-fix,      on: "Categoria: Implementacion" }
  # Sub-DAG 5: Hotfix (crítico)
  - { from: bug-triage, to: implement-fix,      on: "Severidad: Critico" }
  - { from: implement-fix, to: qa-fix }
  - { from: qa-fix, to: hotfix-deploy,          on: PASS }
  # Flujo normal
  - { from: implement-fix, to: qa-fix }
  - { from: qa-fix, to: tech-review-final }
  - { from: qa-fix, to: implement-fix,          on: FAIL, retry: 1, back: true }
  - { from: tech-review-final, to: deploy,      on: PASS }
  - { from: tech-review-final, to: implement-fix, on: FAIL, retry: 1, back: true }
  - { from: tech-review-final, to: adversarial-review, type: fan-out }
  - { from: adversarial-review, to: deploy,     on: PASS, type: fan-in }
hotfix:
  enabled: true
  from: [qa-fix]
  to: [hotfix-deploy]
  note: Hotfix bypassa el pipeline normal; ver sección "Flujo de Emergencia"
```
<!-- dag:end -->

---

## Pasos Detallados

### Paso 0 — Triaje y Clasificación (QA / Tech Lead)

Al detectar un defecto, se debe abrir un caso de corrección registrando un ID incremental `BUG-NNN` en el registro de IDs de `.ai/context.md` y clasificarlo bajo dos dimensiones:

#### A. Severidad
- 🔴 **Crítico:** Bloqueo completo del sistema, pérdida de integridad de datos o brecha de seguridad. Activa el pipeline de **Hotfix**.
- 🟠 **Alto:** Funcionalidad principal rota sin alternativa de uso temporal (workaround).
- 🟡 **Medio:** Fallo en funcionalidad secundaria o existe un workaround viable.
- 🟢 **Bajo:** Defecto cosmético o comportamiento visual menor que no interrumpe la operación.

#### B. Categoría e Impacto (Activa el Sub-pipeline)

| Categoría | Causa Raíz | Pipeline de Agentes | Entregables Modificados |
| :--- | :--- | :--- | :--- |
| **1. Negocio o Funcional** | Requerimiento original ambiguo o contradictorio. | Analyst ➡️ Tech Lead ➡️ Developer ➡️ QA | `.ai/features/FEAT-XXX/spec.md` o `.ai/business-rules.md` |
| **2. Visual o UI/UX** | Problemas de responsive, fallos visuales o estados omitidos. | UI Designer ➡️ Developer ➡️ QA | `.ai/features/FEAT-XXX/ui-design.md` o `ui-review.md` |
| **3. Arquitectura / Técnico** | Mal diseño de BD, condición de carrera o fallo de integración. | Architect ➡️ Tech Lead ➡️ Developer ➡️ QA | `.ai/features/FEAT-XXX/architecture.md` o `.ai/architecture.md` |
| **4. Implementación Pura** | Error lógico del Developer; la especificación y el diseño visual/técnico son correctos. | Developer ➡️ QA | Solo archivos de código del proyecto |

---

### Paso 1 — Ajuste Documental (Dinámico por Agente)

Según la clasificación del bug, se activa el agente correspondiente para corregir el diseño antes de tocar código:

#### 1.A. Ajuste de Especificación Funcional (Product Analyst)
*Se activa si el bug es funcional o de negocio.*
- **Entrada:** Reporte de bug.
- **Acción:** Corregir `.ai/features/FEAT-XXX/spec.md` (o crearla en `.ai/features/BUG-NNN-slug/spec.md` si es general) y actualizar `.ai/business-rules.md` si aplica.
- **Cierre Obligatorio (R6):**
  ```bash
  bash .ai/agents/scripts/finish-phase.sh BUG-NNN analysis analyst
  # Flags opcionales: --tokens-in <N> --tokens-out <N> --duration <S> --source measured
  ```
- **Aprobación:** El Tech Lead debe validar los cambios funcionales antes de que pasen al Developer.

#### 1.B. Ajuste de Especificación Visual (UI Designer)
*Se activa si el bug es de UI/UX, responsive, o a11y.*
- **Entrada:** Reporte de bug + `ui-design.md` anterior.
- **Acción:** Modificar el diseño en `ui-design.md` para corregir la alineación, adaptabilidad o definir el estado visual omitido.
- **Cierre Obligatorio (R6):**
  ```bash
  bash .ai/agents/scripts/finish-phase.sh BUG-NNN ui-design ui-designer
  # Flags opcionales: --tokens-in <N> --tokens-out <N> --duration <S> --source measured
  ```

#### 1.C. Ajuste de Diseño Técnico (Software Architect)
*Se activa si el bug es arquitectónico o de lógica técnica compleja.*
- **Entrada:** Reporte de bug + diseño técnico actual.
- **Acción:** Actualizar `architecture.md` de la feature o el archivo de arquitectura global `.ai/architecture.md`. Si se toma una decisión de diseño de impacto general, registrar una nueva decisión `ARCH-NNN` en `.ai/decisions.md` y `.ai/knowledge-graph.yaml`.
- **Cierre Obligatorio (R6):**
  ```bash
  bash .ai/agents/scripts/finish-phase.sh BUG-NNN architecture architect
  # Flags opcionales: --tokens-in <N> --tokens-out <N> --duration <S> --source measured
  ```
- **Aprobación:** El Tech Lead debe revisar y aprobar el diseño técnico modificado.

---

### Paso 2 — Implementación de la Corrección (Developer)

**Agente:** Senior Developer  
**Entradas:** Reporte del bug + especificaciones modificadas (funcional, visual o técnica, según aplique).

#### 🎯 Sub-paso 2.1: Localización del Defecto (Pinpoint Bug Scope)
Antes de modificar archivos:
1. **Localizar la causa raíz:** Identificar con precisión el archivo, la función y las líneas causantes del bug.
2. **Delimitar el cambio:** Restringir el alcance exclusivamente al fix para evitar introducir regresiones.

**Activación:**
```
Actúa como el agente Senior Developer definido en roles/developer.md.
Tengo el bug BUG-NNN clasificado como [Categoría] con severidad [Severidad].

Reporte del Bug: [Detalles del comportamiento incorrecto]
Especificación de corrección de referencia:
[Contenido de spec.md, ui-design.md o architecture.md modificados en el Paso 1]
```

**Reglas de Corrección:**
- La intervención de código debe ser **mínima y enfocada** estrictamente a resolver el bug.
- Escribir o actualizar una prueba automatizada (unit/integration) que reproduzca el bug y valide que no vuelva a ocurrir (Regression Test).
- Queda estrictamente prohibido realizar refactorizaciones o agregar features no relacionadas (scope creep) dentro del fix.
- Si el fix requiere modificar APIs o esquemas de BD no contemplados en el Paso 1.C, detener la implementación y notificar al Architect.
- **Cierre Obligatorio (R6):** Al finalizar la implementación y tests, el Developer **debe ejecutar obligatoriamente**:
  ```bash
  bash .ai/agents/scripts/finish-phase.sh BUG-NNN implement developer
  # Flags opcionales: --tokens-in <N> --tokens-out <N> --duration <S> --source measured
  ```

---

### Paso 3 — Validación y Self-Healing Loop (QA)

**Agente:** QA Engineer  
**Entradas:** Cambios implementados + Reporte del Bug + Checklist de verificación.

**Activación:**
```
Actúa como el agente QA Engineer definido en roles/qa.md.
Estoy validando la resolución de BUG-NNN.

Reporte del bug original: [Detalles]
Cambios realizados: [Lista de commits o descripción de modificaciones de código]
```

**Flujo de Verificación y Autocorrección:**
- Si el bug era **Visual/UI-UX**, el QA Engineer (o el UI Designer) debe auditar los cambios contra el checklist [`checklists/ui-review.md`](../checklists/ui-review.md).
- Si el bug era **Técnico**, validar que no haya regresiones en endpoints o integraciones mediante [`checklists/frontend-review.md`](../checklists/frontend-review.md) o [`checklists/backend-review.md`](../checklists/backend-review.md).
- **Self-Healing Loop:** Si la prueba falla (`FAIL` / `RECHAZADO`):
  1. El QA genera en `qa.md` el diagnóstico estructurado con logs de error y pasos de reproducción.
  2. El Developer ajusta el parche de forma inmediata y re-ejecuta los tests.
  3. Se repite el ciclo hasta que el veredicto sea `APROBADO` (máximo 3 intentos antes de escalar al Tech Lead).
- **Cierre Obligatorio (R6):** Al emitir el reporte `qa.md`, ejecutar:
  ```bash
  bash .ai/agents/scripts/finish-phase.sh BUG-NNN qa qa --verdict <APROBADO|RECHAZADO>
  # Flags opcionales: --tokens-in <N> --tokens-out <N> --duration <S> --source measured
  ```

---

### Paso 4 — Veredicto Final (Tech Lead)

El Tech Lead revisa la trazabilidad del bug:
- ¿Se documentó correctamente el bug y su causa raíz?
- ¿Participaron los agentes necesarios según su impacto?
- ¿El reporte de QA está en `PASS`?
Si todo está conforme, emite el veredicto de `APROBADO` para el deployment.

**Interacción Interactiva (Commit, Push y Release):**
> [!IMPORTANT]
> Una vez que el Tech Lead apruebe la corrección, la IA **debe guiar activamente al usuario** en:
> 1. **Commit y Push:** Proponer un mensaje de commit (ej. `fix(scope): BUG-NNN - descripcion`). Preguntar al usuario si desea proceder.
> 2. **Version Bump:** Una vez hecho el commit, ejecutar `npm run bump:patch -- "BUG-NNN: descripción"` para actualizar la versión (patch), el CHANGELOG y el context.
> 3. **Git Tag:** Crear tag `git tag -a vX.Y.Z -m "BUG-NNN: descripción"` y push con `git push --tags`.
> 4. **Release:** Indicar al usuario si procede release según [`workflows/release.md`](release.md).
> 5. **Cierre Obligatorio (R6):**
>    ```bash
>    bash .ai/agents/scripts/finish-phase.sh BUG-NNN approval tech-lead --verdict APROBADO [--archive]
  # Flags opcionales: --tokens-in <N> --tokens-out <N> --duration <S> --source measured
>    ```

---

### Paso 5 — Deploy y Cierre

1. Desplegar el fix a producción (ver [`workflows/release.md`](release.md)).
2. Ejecutar el cierre y archivado final:
   ```bash
   bash .ai/agents/scripts/finish-phase.sh BUG-NNN deploy devops --verdict PASS --archive
  # Flags opcionales: --tokens-in <N> --tokens-out <N> --duration <S> --source measured
   ```
3. Consolidar cambios en la memoria del proyecto:
   - Si se modificó la arquitectura, actualizar `.ai/architecture.md`.
   - Si se modificó una regla funcional, actualizar `.ai/business-rules.md`.
4. Actualizar `CHANGELOG.md` documentando el bug resuelto en la sección de "Fixed" (esto ya se hizo automáticamente en el Paso 4 con `npm run bump:patch`).

---

## Flujo de Emergencia: Hotfix Crítico 🔴

Si la severidad es **Crítica** y el sistema o datos están comprometidos, el flujo dinámico se optimiza para minimizar el tiempo de inactividad:

1. **Bypass del Pipeline:** El Developer inicia la corrección directamente en una rama `hotfix/BUG-NNN` basada en `main`.
2. **Validación Rápida:** QA realiza pruebas de humo rápidas directamente sobre el fix enfocado.
3. **Despliegue Inmediato:** Se realiza el deploy de emergencia con aprobación verbal del Tech Lead.
4. **Documentación Post-Mortem:** Dentro de las 24 horas posteriores al deploy, el Tech Lead convoca a los agentes (Analyst, Architect, UI Designer, según corresponda) para:
   - Analizar la causa raíz.
   - Actualizar retroactivamente la documentación técnica o funcional (`context.md`, `architecture.md`, `business-rules.md`).
   - Registrar la lección aprendida en `.ai/decisions.md` para prevenir recurrencia.

---

## Checklist de Cierre y Archivado de Bug Fix

- [ ] Identificado e incrementado el ID del bug `BUG-NNN` en `.ai/context.md`.
- [ ] Bug clasificado por Severidad y Categoría en el triaje.
- [ ] **Documentación ajustada:**
  - [ ] `spec.md` modificada por el Analyst (si el bug fue de Negocio).
  - [ ] `ui-design.md` modificada por el UI Designer (si el bug fue Visual).
  - [ ] `architecture.md` / `decision.md` modificada por el Architect / Tech Lead (si el bug fue Técnico).
- [ ] Corrección de código enfocada y sin adición de código externo o refactores.
- [ ] QA validó el fix con veredicto `APROBADO`.
- [ ] Veredicto del Tech Lead: `APROBADO`.
- [ ] Usuario validó en entorno de pruebas / staging.
- [ ] Despliegue a producción completado con éxito.
- [ ] Bug archivado automáticamente a `.ai/archive/` (`bash .ai/agents/scripts/archive-initiative.sh BUG-NNN`).
- [ ] Memoria del proyecto (`.ai/memory/workflow-log.md`, `context-snapshot.md`) y Knowledge Graph actualizados.
- [ ] `CHANGELOG.md` del proyecto actualizado.
- [ ] Versión bumpeda (`npm run bump:patch`).
- [ ] Git tag `vX.Y.Z` creado y pusheado.

---

*Workflow bug-fix v3.4.0 — ai-agents library | github.com/ezequielmendoza-dev/ai-agents*
