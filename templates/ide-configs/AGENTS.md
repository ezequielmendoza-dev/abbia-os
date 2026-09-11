# 🤖 Agentes de IA — Guía de Desarrollo Asistido

> Este documento es la **fuente de verdad** sobre cómo funciona el sistema de desarrollo asistido por IA en este proyecto.
> Debe ser leído por cualquier asistente de IA (Cursor, Claude Code, Windsurf, Cline, Copilot) antes de realizar cualquier tarea.
> **Importante:** Para comprender el contexto de negocio, stack técnico y especificaciones particulares de este proyecto, la IA debe leer primero [.ai/context.md](file:///.ai/context.md).

> **ℹ️ Relación con `AGENTS.md` (raíz):** Este archivo es la plantilla instalada en los proyectos que **consumen** `ai-agents`. El `AGENTS.md` que vive en la raíz del *repo* `ai-agents` es un documento **distinto**: describe cómo portar cambios al framework (reglas documentales R1–R5, estructura interna del repo). No confundir ambos roles — si estás contribuyendo al repo, usa el de la raíz; si estás trabajando en un proyecto integrado, usa este.

---

## 📂 Arquitectura Documental y Memoria (.ai/)

Este proyecto mantiene una jerarquía estricta de dos niveles en la carpeta `.ai/`:

### 1. Memoria Permanente (raíz de `.ai/`)

Estos archivos representan el **estado actual** del proyecto y deben consultarse antes de cualquier tarea:

| Archivo | Propósito |
| :--- | :--- |
| `.ai/context.md` | Identidad del proyecto: stack, módulos, convenciones, entornos |
| `.ai/business-rules.md` | Reglas de negocio permanentes del dominio |
| `.ai/architecture.md` | Arquitectura actual del sistema en producción |
| `.ai/decisions.md` | Log histórico de decisiones técnicas (ADRs: `ARCH-NNN`) |
| `.ai/glossary.md` | Términos de negocio acordados con definiciones |
| `.ai/knowledge-graph.yaml` | Grafo de relaciones entre decisiones (depends_on, supersedes, conflicts_with) |
| `.ai/memory/*` | Memoria persistente del pipeline (workflow-log, decisions-catalog, patterns-learned, context-snapshot) |
| `.ai/metrics/*` | Métricas por ejecución de agente (tokens, duración, fase, veredicto) |

### 2. Trabajo Activo (`.ai/features/`)

Toda nueva iniciativa (feature, bug, refactor) se desarrolla dentro de su propia carpeta:
- Features: `.ai/features/FEAT-NNN-slug/`
- Bugs: `.ai/features/BUG-NNN-slug/`

Los documentos de especificación, diseño técnico y QA viven **únicamente** dentro de estas carpetas hasta que se consoliden en la memoria permanente al finalizar el ciclo.

### 📋 Reglas Documentales Críticas

| Regla | Enunciado |
| :--- | :--- |
| **R1** | Antes de crear un documento, verificar si existe uno equivalente para actualizar |
| **R2** | Priorizar la **actualización** sobre la creación |
| **R3** | No crear versiones del tipo `architecture-v2.md` o `spec-final.md` — modificar el existente |
| **R4** | No crear documentos de features específicas en la raíz de `.ai/` |
| **R5** | Los documentos raíz representan el **estado actual**, no el histórico |

---

## 👥 Roles de los Agentes

Para cualquier tarea compleja, la IA debe asumir uno de los siguientes roles especializados. Antes de actuar, **leer completo** el archivo del rol correspondiente:

| Agente / Rol | Archivo de Instrucciones | Responsabilidad Principal |
| :--- | :--- | :--- |
| **Skill Manager** | `.ai/agents/roles/skill-manager.md` | Orquestación, descubrimiento, resolución de skills y recomendación de catálogo externo (skills.sh) |
| **Product Analyst** | `.ai/agents/roles/analyst.md` | Clarificar requerimientos y escribir especificaciones funcionales (`spec.md`) |
| **UI Designer** | `.ai/agents/roles/ui-designer.md` | Diseñar la interfaz visual, layout, estados y lineamientos de accesibilidad (`ui-design.md`) |
| **Software Architect** | `.ai/agents/roles/architect.md` | Diseñar soluciones técnicas y documentar en `architecture.md` (ADRs) |
| **Tech Lead** | `.ai/agents/roles/tech-lead.md` | Revisar diseños y código, validar adherencia a estándares, actuar como árbitro |
| **Senior Developer** | `.ai/agents/roles/developer.md` | Escribir código limpio, tests unitarios y asegurar calidad de implementación |
| **QA Engineer** | `.ai/agents/roles/qa.md` | Validar la implementación contra las especificaciones, crear reportes de prueba |
| **DevOps Engineer** | `.ai/agents/roles/devops.md` | Configurar pipelines, CI/CD, infraestructura y configuraciones de nube |

### Restricciones por Diseño

- Cada agente tiene **constraints explícitos** que definen lo que **NO** puede hacer.
- Ningún agente debe invadir el rol de otro.
- Cada agente tiene reglas de documentación que establecen cuándo crear, cuándo actualizar, y cómo distinguir información permanente vs. temporal.

### 💬 Protocolo de Clarificación Proactiva

Todos los agentes siguen este protocolo antes de producir su output:

1. **Evaluar ambigüedades de negocio:** Antes de actuar, el agente evalúa si existen dudas sobre la lógica de negocio, el alcance funcional o las prioridades del proyecto que le impidan producir un output completo y correcto.
2. **Preguntar solo lo necesario:** Si existen ambigüedades, el agente se detiene y formula preguntas concisas al usuario (idealmente 3-5 preguntas agrupadas, nunca un interrogatorio extenso).
3. **Autonomía técnica total:** Las decisiones dentro del área de expertise del agente (patrones de diseño, estructura de código, estrategia de testing, configuración de infraestructura, diseño visual, etc.) se resuelven de forma autónoma sin consultar al usuario.
4. **No preguntar lo documentado:** El agente no debe preguntar sobre convenciones, stack o arquitectura que ya estén documentados en `.ai/context.md`, `.ai/architecture.md` o `.ai/business-rules.md`.
5. **Asumir con criterio experto:** Ante detalles menores o no críticos, el agente puede tomar decisiones razonables y documentar las asunciones realizadas en su output.

---

## 🔄 Flujos de Trabajo (Workflows)

La IA debe seguir estrictamente los workflows detallados en `.ai/agents/workflows/`:

| Workflow | Archivo | Pipeline |
| :--- | :--- | :--- |
| **Nueva Feature** | `new-feature.md` | Analyst (Spec) ➡️ UI Designer (UI) ➡️ Architect (Design) ➡️ Tech Lead (Approval) ➡️ Developer (Code) ➡️ QA (Validation) ➡️ Release |
| **Corrección de Bugs** | `bug-fix.md` | Dinámico (QA ➡️ Triaje ➡️ Analyst/UI/Architect [según origen] ➡️ Developer ➡️ QA ➡️ Tech Lead) |
| **Refactorización** | `refactor.md` | Plan ➡️ Cobertura de tests ➡️ Modificación incremental ➡️ Verificación de comportamiento |
| **Release** | `release.md` | Verificación QA completa ➡️ Checklists ➡️ Deploy |
| **Cambio Arquitectónico** | `architecture-change.md` | Creación de ADR ➡️ Actualización de planos globales ➡️ Ejecución migratoria |

---

## 📝 Templates Disponibles

Los templates se encuentran en `.ai/agents/templates/` y deben usarse como base para crear documentos:

| Template | Uso |
| :--- | :--- |
| `feature-spec.md` | Especificación funcional de una feature |
| `ui-design-spec.md` | Plantilla para el diseño visual de interfaz de una feature |
| `architecture-spec.md` | Diseño técnico de una feature |
| `technical-task.md` | Tarea técnica para el Developer |
| `qa-report.md` | Reporte de validación de QA |
| `bug-report.md` | Reporte estructurado de bugs |
| `project-context.md` | Plantilla base para `.ai/context.md` |
| `feature-folder-template.md` | Estructura estándar de carpeta por feature |

---

## ✅ Checklists

Antes de un release o revisión, verificar los checklists en `.ai/agents/checklists/`:

| Checklist | Área / Propósito |
| :--- | :--- |
| `frontend-review.md` | Revisión de código frontend, semántica HTML y responsividad |
| `ui-review.md` | Revisión de UI/UX, consistencia visual y accesibilidad |
| `backend-review.md` | Revisión de código backend, APIs y manejo de errores |
| `database-review.md` | Revisión de base de datos, índices y consistencia de datos |
| `security-review.md` | Auditoría de seguridad: autenticación, validación de datos y secretos |
| `performance-review.md` | Validación de rendimiento: optimizaciones, consultas lentas y leaks |
| `release-review.md` | Checklist operacional para lanzamientos seguros y planes de rollback |

---

## ⚙️ Scripts de Automatización

El proyecto cuenta con herramientas en `.ai/agents/scripts/` para simplificar flujos comunes de desarrollo:

| Script | Uso / Propósito |
| :--- | :--- |
| `setup-ide.sh` | Regenerar configuraciones de IDEs o inicializar carpetas: `bash .ai/agents/scripts/setup-ide.sh` |
| `update-ai-agents.sh` | Actualizar el framework en un comando (submodule + setup): `bash .ai/agents/scripts/update-ai-agents.sh [vX.Y.Z]` |
| `new-initiative.sh` | Crear nueva iniciativa (FEAT/BUG/AUDIT/REF) automáticamente: `bash .ai/agents/scripts/new-initiative.sh <TIPO> <ID> <slug>` |
| `validate-project.sh` | Validar conformidad del proyecto local con las reglas documentales: `bash .ai/agents/scripts/validate-project.sh` |
| `common.sh` | Librería compartida de soporte (interno, DRY) |

---

## 🏷️ Convenciones de Nomenclatura

| Tipo | Formato | Ejemplo |
| :--- | :--- | :--- |
| Feature | `FEAT-NNN-slug` | `FEAT-001-user-login` |
| Bug | `BUG-NNN-slug` | `BUG-024-db-connection-timeout` |
| ADR | `ARCH-NNN` | `ARCH-003` |
| Branch feature | `feat/NNN-slug` | `feat/001-user-login` |
| Branch fix | `fix/NNN-slug` | `fix/024-db-connection-timeout` |

---

## 💡 Cómo Instanciar un Agente (Prompts)

Para activar un agente de IA en su rol respectivo, utilizar una de las siguientes plantillas:

### Product Analyst (Análisis de Feature)
```
Actúa como el agente Product Analyst definido en .ai/agents/roles/analyst.md.
Nuestra feature actual es: FEAT-NNN-slug
Requerimiento original: [Descripción breve de la idea]
Genera el archivo .ai/features/FEAT-NNN-slug/spec.md.
```

### Product Analyst (Bootstrap / Auto-Contextualización)
```
Actúa como el agente Product Analyst definido en .ai/agents/roles/analyst.md y genera el archivo `.ai/context.md` de este proyecto basándote en la plantilla `.ai/agents/templates/project-context.md` tras escanear la estructura y archivos de configuración.
```

### UI Designer
```
Actúa como el agente UI Designer definido en .ai/agents/roles/ui-designer.md.
Nuestra feature actual es: FEAT-NNN-slug
Genera el diseño visual en .ai/features/FEAT-NNN-slug/ui-design.md basándote en la especificación en .ai/features/FEAT-NNN-slug/spec.md.
```

### Software Architect
```
Actúa como el agente Software Architect definido en .ai/agents/roles/architect.md.
Nuestra feature actual es: FEAT-NNN-slug.
Lee la especificación funcional en .ai/features/FEAT-NNN-slug/spec.md y genera el diseño técnico en .ai/features/FEAT-NNN-slug/architecture.md, incluyendo cualquier ADR nuevo que deba registrarse en .ai/decisions.md.
```

### Tech Lead
```
Actúa como el agente Tech Lead definido en .ai/agents/roles/tech-lead.md.
Nuestra feature actual es: FEAT-NNN-slug
Revisa el archivo de especificación (.ai/features/FEAT-NNN-slug/spec.md) y de diseño (.ai/features/FEAT-NNN-slug/architecture.md). Evalúa si cumplen con los estándares y convenciones del proyecto y da tu feedback o aprobación.
```

### Senior Developer
```
Actúa como el agente Senior Developer definido en .ai/agents/roles/developer.md.
Nuestra feature actual es: FEAT-NNN-slug
Implementa el código correspondiente a la tarea detallada en la especificación (.ai/features/FEAT-NNN-slug/spec.md) y el diseño técnico (.ai/features/FEAT-NNN-slug/architecture.md). Escribe tests y adhiérete a las guías de estilo.
```

### QA Engineer
```
Actúa como el agente QA Engineer definido en .ai/agents/roles/qa.md.
Nuestra feature actual es: FEAT-NNN-slug
Efectúa la verificación de la implementación. Revisa el código frente a la especificación funcional y el diseño, y redacta el reporte en .ai/features/FEAT-NNN-slug/qa.md.
```

---

## 📚 Guía de Prompts Completa

Para ejemplos avanzados de prompts y patrones de activación de agentes, consultar:
`.ai/agents/roles/prompt-guide.md`
