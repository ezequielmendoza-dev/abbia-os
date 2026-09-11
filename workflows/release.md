# Workflow: Release

> **Versión:** 1.0  
> **Agentes involucrados:** Tech Lead → DevOps

---

## Cuándo usar este workflow

- Una o más features pasaron QA y están listas para producción
- Hay una corrección de bug crítico que debe desplegarse
- Se definió una cadencia de releases (semanal, quincenal, etc.)

---

## Tipos de Release

| Tipo | Descripción | Ejemplo de versión |
|------|-------------|-------------------|
| **Major** | Cambios que rompen compatibilidad hacia atrás | `1.0.0` → `2.0.0` |
| **Minor** | Nuevas funcionalidades sin breaking changes | `1.0.0` → `1.1.0` |
| **Patch** | Bug fixes y correcciones menores | `1.0.0` → `1.0.1` |
| **Hotfix** | Corrección urgente de bug crítico en producción | Branch `hotfix/` desde `main` |

---

## Flujo — Release Normal

```mermaid
flowchart TD
    A[Features con QA PASS listas] --> B[Tech Lead: Revisar checklist pre-release]
    B --> C{¿Todo en orden?}
    C -->|No| D[Resolver issues bloqueantes]
    D --> B
    C -->|Sí| E[Tech Lead: Definir scope del release]
    E --> F[DevOps: Preparar release]
    F --> G[Deploy a Staging]
    G --> H[QA: Smoke test en Staging]
    H --> I{¿Smoke test OK?}
    I -->|Falla| J[Developer: Corregir en Staging]
    J --> H
    I -->|OK| K[Tech Lead: Aprobación final]
    K --> L[DevOps: Deploy a Producción]
    L --> M[DevOps: Verificar salud post-deploy]
    M --> N{¿Sistema saludable?}
    N -->|No| O[DevOps: Rollback]
    N -->|Sí| P[Tech Lead: Release confirmado]
    P --> Q[Actualizar CHANGELOG.md y versión]
```

---

<!-- dag:start -->
**Modos de ejecución:** `rápido` | `estándar` (default) | `profundo` (ver `docs/workflow-dag.md`)

```yaml
name: release
modes:
  rapido:
    truncate: [staging, smoke-staging]
    note: Para hotfixes unda — deploy directo con smoke en producción
  estandar: {}
  profundo:
    extra: [post-release-monitoring]
nodes:
  pre-release-check:
    agent: tech-lead
    input: [features QA PASS, contexto]
    output: [checklist verificado]
    gate: true
  resolve-blockers:
    agent: tech-lead
    input: [issues bloqueantes]
    output: [blockers resueltos]
    parallel: false
  scope-release:
    agent: tech-lead
    input: [checklist verificado]
    output: [scope RELEASE vX.Y.Z]
    parallel: false
  prepare-release:
    agent: devops
    input: [scope, contexto]
    output: [plan de deploy y rollback]
    parallel: false
  staging:
    agent: devops
    input: [plan de deploy]
    output: [staging desplegado]
    parallel: false
  smoke-staging:
    agent: qa
    input: [staging desplegado]
    output: [smoke-test]
    parallel: false
  fix-in-staging:
    agent: developer
    input: [fallos del smoke-test]
    output: [fix en staging]
    parallel: false
  approve-release:
    agent: tech-lead
    input: [smoke-test]
    output: [verdict]
    gate: true
  deploy-prod:
    agent: devops
    input: [aprobación, plan de rollback]
    output: [producción desplegada]
    parallel: false
  post-deploy-health:
    agent: devops
    input: [producción desplegada]
    output: [health report]
    parallel: false
  post-release-monitoring:
    agent: devops
    input: [producción desplegada]
    output: [monitor 15-min]
    parallel: false
  rollback:
    agent: devops
    input: [plan de rollback]
    output: [versión anterior restaurada]
    parallel: false
  post-mortem:
    agent: tech-lead
    input: [rollback aplicado]
    output: [post-mortem.md]
    parallel: false
  confirm-release:
    agent: tech-lead
    input: [health report]
    output: [release confirmado]
    gate: true
  cierre:
    agent: tech-lead
    input: [release confirmado]
    output: [CHANGELOG, tags, archivado]
    parallel: false
edges:
  - { from: pre-release-check,  to: resolve-blockers,    on: ISSUES }
  - { from: resolve-blockers,   to: pre-release-check,   retry: 1, back: true }
  - { from: pre-release-check,  to: scope-release,       on: OK }
  - { from: scope-release,      to: prepare-release }
  - { from: prepare-release,    to: staging }
  - { from: staging,            to: smoke-staging }
  - { from: smoke-staging,      to: fix-in-staging,      on: FALLO }
  - { from: fix-in-staging,     to: staging,             retry: 1, back: true }
  - { from: smoke-staging,      to: approve-release,     on: OK }
  - { from: approve-release,    to: deploy-prod,         on: APROBADO }
  - { from: approve-release,    to: fix-in-staging,      on: RECHAZADO, retry: 1, back: true }
  - { from: deploy-prod,        to: post-deploy-health }
  - { from: post-deploy-health, to: rollback,            on: UNHEALTHY }
  - { from: post-deploy-health, to: confirm-release,     on: HEALTHY }
  - { from: post-deploy-health, to: post-release-monitoring, type: fan-out }   # solo profundo
  - { from: rollback,           to: post-mortem }
  - { from: confirm-release,    to: cierre,              on: CONFIRMADO }
hotfix:
  enabled: true
  from: [deploy-prod]
  to: [main]
  note: Hotfix = deploy directo a producción sin staging; ver sección "Flujo — Hotfix"
```
<!-- dag:end -->

---

## Pasos Detallados

### Paso 0 — Leer el estado actual

Antes de cualquier release:

1. Leer `.ai/context.md` para conocer el stack y entornos
2. Revisar todas las features en `.ai/features/` con QA PASS
3. Revisar `.ai/decisions.md` por decisiones recientes que impacten el release

---

### Paso 1 — Checklist Pre-Release (Tech Lead)

**Agente:** Tech Lead  
**Verificar para cada feature incluida en el release:**

- [ ] `spec.md` en estado `Aprobada`
- [ ] `architecture.md` en estado `Aprobado`
- [ ] `qa.md` con resultado `PASS` o `PASS WITH OBSERVATIONS` resueltas
- [ ] Veredicto del Tech Lead previo: `APROBADO`
- [ ] Código en rama principal o rama de release
- [ ] Sin conflictos de merge pendientes

**Verificar a nivel de sistema:**

- [ ] No hay bugs críticos abiertos (`BUG-NNN` con severidad 🔴) sin resolver
- [ ] Las migraciones de base de datos están preparadas y testeadas en staging
- [ ] Las variables de entorno de producción están actualizadas
- [ ] El plan de rollback está documentado

---

### Paso 2 — Scope del Release (Tech Lead)

Definir explícitamente:

```markdown
## Release vX.Y.Z — [Fecha]

### Features incluidas
- FEAT-NNN: [nombre]
- FEAT-NNN: [nombre]

### Bug fixes incluidos
- BUG-NNN: [descripción]

### Features NO incluidas (quedan para el siguiente release)
- FEAT-NNN: [nombre] — [razón por la que queda afuera]
```

---

### Paso 3 — Preparación del Release (DevOps)

**Agente:** DevOps Engineer  
**Activación:**

```
Actúa como el agente DevOps Engineer definido en roles/devops.md.

Contexto del proyecto: [contenido de .ai/context.md]

Tarea: Preparar el release vX.Y.Z

Features incluidas:
[lista de FEAT-NNN]

Bug fixes incluidos:
[lista de BUG-NNN]

Migraciones de base de datos requeridas:
[lista si aplica]
```

**Output:** Checklist de deployment, comandos de deploy, plan de rollback.

---

### Paso 4 — Deploy a Staging y Smoke Test

1. DevOps despliega a Staging
2. QA ejecuta **smoke test**: verificar que los flujos principales de cada feature incluida funcionan correctamente
3. Si algo falla en Staging → corregir antes de continuar. No ir a Producción con issues conocidos.

---

### Paso 5 — Deploy a Producción

**Solo después de que el smoke test en Staging sea exitoso.**

**Activación:**

```
Actúa como el agente DevOps Engineer definido en roles/devops.md.

Tarea: Deploy a Producción del release vX.Y.Z

El smoke test en Staging fue exitoso.

Plan de rollback aprobado:
[pasos de rollback]
```

---

### Paso 6 — Verificación Post-Deploy

Inmediatamente después del deploy a Producción:

- [ ] Verificar que el sistema responde correctamente (health checks)
- [ ] Verificar que las migraciones de DB corrieron sin errores
- [ ] Monitorear logs por errores inesperados durante los primeros 15 minutos
- [ ] Ejecutar smoke test en Producción (flujos críticos)

Si algo falla → ejecutar el plan de rollback inmediatamente.

---

### Paso 7 — Cierre del Release

> Si las iniciativas individuales ya ejecutaron su bump (según RN-045), el CHANGELOG y la versión ya están actualizados.  
> Este paso es para releases que agrupan múltiples iniciativas sin bumps individuales previos.

1. **Bump de versión global** (solo si no se bumpcaron individualmente):
   ```bash
   npm run bump:minor "Release vX.Y.Z - descripción"
   ```
   O ajustar `major`/`patch` según el contenido del release.
2. **Mover features** a `archive/` en `.ai/`:
   ```bash
   mv .ai/features/FEAT-NNN-slug .ai/archive/FEAT-NNN-slug
   ```
3. **Actualizar documentos permanentes** si el release cambió algo global:
   - `.ai/architecture.md`
   - `.ai/business-rules.md`
   - `.ai/glossary.md`
4. **Crear tag de Git** con la versión del release:
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z — [descripción breve]"
   git push origin vX.Y.Z
   ```

---

## Flujo — Hotfix (bug crítico en producción)

```mermaid
flowchart TD
    A[🔴 Bug crítico en Producción] --> B[Tech Lead: Evaluar impacto]
    B --> C[Crear branch hotfix/slug desde main]
    C --> D[Developer: Corregir el bug]
    D --> E[QA: Validar la corrección]
    E --> F{¿Corrección OK?}
    F -->|No| D
    F -->|Sí| G[Tech Lead: Aprobar el hotfix]
    G --> H[DevOps: Deploy directo a Producción]
    H --> I[Verificar salud post-deploy]
    I --> J[Hacer merge del hotfix a develop/main]
    J --> K[Documentar en decisions.md si aplica]
```

**Reglas del hotfix:**
- Un hotfix es solo para bugs críticos que afectan producción ahora
- Va directo a Producción sin esperar el ciclo de release normal
- Debe hacerse merge también a la rama de desarrollo para no perder la corrección
- Post-mortem documentado en `.ai/decisions.md` para entender y prevenir

---

## Plan de Rollback Estándar

Si el deploy a Producción genera un problema que no puede corregirse en minutos:

1. **Notificar** al equipo y al Tech Lead del inicio del rollback
2. **Revertir** el deploy (según la estrategia: redeploy de la versión anterior, feature flags, etc.)
3. **Verificar** que el sistema volvió al estado estable anterior
4. **Documentar** qué ocurrió en `.ai/decisions.md`
5. **Postmortem** para entender la causa raíz antes de reintentar el release

---

*Workflow release v1.0 — ai-agents library | github.com/ezequielmendoza-dev/ai-agents*
