# 🏛️ Abbia OS — Guía de Desarrollo Asistido por IA

> Este documento es la **fuente de verdad** sobre cómo opera el sistema de ingeniería asistida por IA (**Abbia OS**) en este proyecto.
> Debe ser leído por cualquier asistente o agente de IA (Cursor, Claude Code, Windsurf, Cline, Copilot, Antigravity) antes de realizar cualquier tarea.
> **Lema de Abbia:** *Layered Context, Structured Memory, Autonomous Delivery.*
> **Contexto de Negocio:** Para comprender el stack técnico, entidades y especificaciones del proyecto, leer primero [.abbia/context.md](file:///.abbia/context.md).

---

## 📂 Arquitectura Documental y Memoria (.abbia/)

Este proyecto mantiene una estructura modular y jerárquica en la carpeta `.abbia/`:

### 1. Memoria Permanente y Gobernanza (raíz de `.abbia/`)

Estos artefactos representan el **estado actual** del proyecto:

| Archivo | Propósito |
| :--- | :--- |
| `.abbia/context.md` | Identidad del proyecto: stack, módulos, convenciones, entornos |
| `.abbia/business-rules.md` | Reglas de negocio permanentes e inmutables del dominio |
| `.abbia/architecture.md` | Arquitectura actual del sistema en producción |
| `.abbia/decisions.md` | Log histórico de decisiones técnicas (ADRs: `ARCH-NNN`) |
| `.abbia/glossary.md` | Términos de negocio acordados con definiciones |
| `.abbia/knowledge-graph.yaml` | Tier 3: Grafo de relaciones entre decisiones (depends_on, supersedes, conflicts_with) |
| `.abbia/memory/*` | Abbia 3-Tier Memory (workflow-log, patterns-learned, context-snapshot) |
| `.abbia/metrics/*` | Abbia Observability: Telemetría por ejecución de agente (tokens, duración, fase) |

### 2. Trabajo Activo (`.abbia/initiatives/`)

Toda nueva iniciativa (feature, bug, refactor, auditoría) se desarrolla dentro de su propia carpeta:
- Features: `.abbia/initiatives/FEAT-NNN-slug/`
- Bugs: `.abbia/initiatives/BUG-NNN-slug/`
- Auditorías: `.abbia/initiatives/AUDIT-NNN-slug/`
- Refactors: `.abbia/initiatives/REF-NNN-slug/`

Los documentos de especificación (`spec.md`), diseño técnico (`architecture.md`) y validación (`qa.md`) viven dentro de estas carpetas hasta consolidarse en la memoria permanente al archivarse a `.abbia/archive/`.

### 📋 Reglas Documentales Críticas (R1-R6)

| Regla | Enunciado |
| :--- | :--- |
| **R1** | Antes de crear un documento, verificar si existe uno equivalente para actualizar |
| **R2** | Priorizar la **actualización** sobre la creación |
| **R3** | No crear versiones del tipo `architecture-v2.md` o `spec-final.md` — modificar el existente |
| **R4** | No crear documentos de features específicas en la raíz de `.abbia/` |
| **R5** | Los documentos raíz representan el **estado actual**, no el histórico |
| **R6** | **Cierre Mandatorio y Telemetría:** Al culminar cualquier fase o tarea, el agente **DEBE SIEMPRE ejecutar en la terminal** `bash .abbia/core/scripts/finish-phase.sh <INICIATIVA> <FASE> <ROL> --model <MODELO> --tokens-in <IN> --tokens-out <OUT> --duration <S> --source <measured|estimate>` antes de finalizar su turno. |

---

## 👥 Roles de los Agentes en Abbia OS

Para cualquier tarea, la IA debe asumir uno de los siguientes roles especializados con su correspondiente **Context Contract**:

| Agente / Rol | Archivo de Instrucciones | Responsabilidad Principal |
| :--- | :--- | :--- |
| **Skill Manager** | `.abbia/core/roles/skill-manager.md` | Capability & Context Advisor, resolución de skills y memoria técnica |
| **Product Analyst** | `.abbia/core/roles/analyst.md` | Requerimientos, reglas de negocio y especificación funcional (`spec.md`) |
| **UI Designer** | `.abbia/core/roles/ui-designer.md` | Diseño de interfaz visual, tokens, estados y accesibilidad (`ui-design.md`) |
| **Software Architect** | `.abbia/core/roles/architect.md` | Diseño técnico, esquemas de base de datos y ADRs (`architecture.md`) |
| **Tech Lead** | `.abbia/core/roles/tech-lead.md` | Code review, supervisión, staging gate y veredicto final |
| **Senior Developer** | `.abbia/core/roles/developer.md` | Implementación de código limpio, pruebas unitarias y cobertura |
| **QA Engineer** | `.abbia/core/roles/qa.md` | Validación funcional, pruebas E2E, regresión y reporte de QA (`qa.md`) |
| **DevOps Engineer** | `.abbia/core/roles/devops.md` | Pipelines CI/CD, infraestructura, release y despliegue a producción |

---

## 🔄 Abbia Workflows (Flujos con DAG)

Seguir estrictamente los flujos definidos en `.abbia/core/workflows/`:

| Workflow | Archivo | Pipeline |
| :--- | :--- | :--- |
| **Nueva Feature** | `new-feature.md` | Analyst (Spec) ➡️ UI Designer (UI) ➡️ Architect (Design) ➡️ Tech Lead (Approval) ➡️ Developer (Code) ➡️ QA (Validation) ➡️ Release |
| **Corrección de Bugs** | `bug-fix.md` | Dinámico (QA ➡️ Triaje ➡️ Analyst/UI/Architect ➡️ Developer ➡️ QA ➡️ Tech Lead) |
| **Refactorización** | `refactor.md` | Plan ➡️ Cobertura de tests ➡️ Modificación incremental ➡️ Verificación |
| **Release** | `release.md` | Verificación QA completa ➡️ Checklists ➡️ Deploy ➡️ Archivado |
| **Cambio Arquitectónico** | `architecture-change.md` | Creación de ADR ➡️ Actualización de planos globales ➡️ Ejecución |

---

## ⚙️ CLI y Scripts de Automatización

Puedes usar el CLI `./abbia` desde la raíz o ejecutar los scripts en `.abbia/core/scripts/`:

| Comando CLI | Script Equivalente | Propósito |
| :--- | :--- | :--- |
| `./abbia new <TIPO> <ID> <slug>` | `new-initiative.sh` | Crear nueva iniciativa (FEAT/BUG/AUDIT/REF) |
| `./abbia finish <INIT> <FASE> [ROL]` | `finish-phase.sh` | Cierre de fase con telemetría y actualización de snapshot |
| `./abbia archive <INIT>` | `archive-initiative.sh` | Archivar iniciativa a `.abbia/archive/` tras QA Aprobado |
| `./abbia sync [--fix]` | `sync-initiatives.sh` | Sincronizar, reconciliar memoria y auto-reparar |
| `./abbia validate` | `validate-project.sh` | Validar conformidad del proyecto con estándares Abbia |
| `./abbia dashboard` | `dashboard.sh` | Generar y abrir el visualizador interactivo en el navegador |
| `./abbia update [VERSION]` | `update-abbia.sh` | Actualizar el framework Abbia OS a la última versión |

---

## 🌿 Higiene de Git y Prevención de Conflictos

1. **Exclusiones en `.gitignore`:**
   `.abbia/sessions/`, `.abbia/dashboard.html`, `.abbia/memory/context-snapshot.md`, `.abbia/metrics/aggregates.yaml`.
2. **Logs Append-Only en `.gitattributes` (`merge=union`):**
   `.abbia/memory/workflow-log.md merge=union`, `.abbia/metrics/executions.yaml merge=union`.
3. **Reconciliación Post-Merge:**
   Tras realizar `git pull` o `git merge`, ejecutar: `./abbia sync`.

---

## 💡 Cómo Instanciar un Agente

### Product Analyst (Análisis de Feature)
```
Actúa como el agente Product Analyst de Abbia OS (.abbia/core/roles/analyst.md).
Iniciativa: FEAT-NNN-slug
Requerimiento original: [Descripción de la idea]
Genera el artefacto .abbia/initiatives/FEAT-NNN-slug/spec.md.
```

### UI Designer
```
Actúa como el agente UI Designer de Abbia OS (.abbia/core/roles/ui-designer.md).
Iniciativa: FEAT-NNN-slug
Genera el diseño en .abbia/initiatives/FEAT-NNN-slug/ui-design.md basándote en spec.md.
```

### Software Architect
```
Actúa como el agente Software Architect de Abbia OS (.abbia/core/roles/architect.md).
Iniciativa: FEAT-NNN-slug.
Lee spec.md y genera el diseño técnico en .abbia/initiatives/FEAT-NNN-slug/architecture.md, registrando ADRs en .abbia/decisions.md si aplica.
```

### Senior Developer
```
Actúa como el agente Senior Developer de Abbia OS (.abbia/core/roles/developer.md).
Iniciativa: FEAT-NNN-slug
Implementa el código siguiendo spec.md y architecture.md. Escribe tests unitarios y asegura cobertura.
```

### QA Engineer
```
Actúa como el agente QA Engineer de Abbia OS (.abbia/core/roles/qa.md).
Iniciativa: FEAT-NNN-slug
Efectúa la verificación de la implementación y redacta el reporte en .abbia/initiatives/FEAT-NNN-slug/qa.md con veredicto explícito.
```
