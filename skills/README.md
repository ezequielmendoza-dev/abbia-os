# 🧩 Skills — Capacidades Técnicas Reutilizables

> **Versión:** 1.0  
> **Propósito:** Separar el conocimiento técnico específico de los roles de los agentes.

---

## ¿Qué es un Skill?

Un **Skill** es una unidad de conocimiento técnico especializado que define las convenciones, patrones, anti-patrones y mejores prácticas de una tecnología, herramienta o disciplina específica.

Los Skills son **independientes de los roles** — cualquier agente puede consumirlos según las necesidades de la tarea.

### Filosofía

| Dimensión | Responde a... |
|-----------|--------------|
| **Roles** (`roles/`) | ¿Quién hace el trabajo? |
| **Skills** (`skills/`) | ¿Qué sabe hacer? |
| **Workflows** (`workflows/`) | ¿Cómo se trabaja? |
| **Context** (`.ai/`) | ¿Dónde se trabaja? |
| **Orchestrator** (Skill Manager) | ¿Cuándo participa cada componente? |

---

## Estructura

```
skills/
├── README.md           ← Este archivo
├── registry.md         ← Registro centralizado (fuente de verdad)
│
├── analysis/           # Skills de análisis y producto (type: method)
│   ├── requirements-discovery.md
│   └── ux-heuristics.md
│
├── architecture/       # Skills de arquitectura (type: method)
│   ├── api-design.md
│   ├── backend-architecture.md
│   ├── database-design.md
│   ├── performance-tuning.md
│   └── ai-integration.md
│
├── development/        # Skills de desarrollo (type: method)
│   ├── code-review.md
│   ├── frontend-patterns.md
│   └── mobile-development.md
│
├── qa/                 # Skills de QA y calidad (type: method)
│   ├── test-strategy.md
│   ├── testing-automation.md
│   └── security-audit.md
│
└── workflow/           # Skills de proceso y continuidad (type: method)
    ├── release-readiness.md
    └── devops-pipeline.md
```

> **Skills tecnológicas (type: tech):** Las categorías por tecnología (`frontend/`, `backend/`, `database/`, `testing/`, `ux/`, `devops/`, `ai/`) no se almacenan en el framework — se descubren dinámicamente desde `Project` (L1) o `UserExternal` (L2) por el **Skill Manager** (ver `docs/skill-discovery.md` y `registry.md`). Los directorios anteriores son la semilla metodológica del framework.

---

## Formato de un Skill

Cada skill es un archivo Markdown con **frontmatter YAML** para metadatos y **cuerpo Markdown** para instrucciones.

```markdown
---
id: nombre-del-skill
category: analysis | architecture | development | qa | workflow
aliases: [alias1, alias2]
type: method                 # method | tech | business
tags: [tag1, tag2]
dependencies: [skill-id-1, skill-id-2]
version: 1.0
---

# Nombre del Skill

> Descripción breve de una línea.

## Cuándo Usar Este Skill
[Criterios de activación]

## Principios Fundamentales
[Principios rectores]

## [Secciones específicas del dominio]
[Reglas, patrones, checklists]

## Anti-Patrones
[Errores comunes a evitar]

## Integración con Otros Skills
[Cómo se relaciona con otros skills]
```

---

## Convenciones

### Nomenclatura
- **IDs de skills:** `kebab-case` (ej: `github-actions`, `design-system`)
- **Archivos:** `kebab-case.md` dentro de la categoría correspondiente
- **Categorías:** Nombres en plural, minúsculas (`analysis`, `architecture`, `development`, `qa`, `workflow`)
- **Tipos:** `method` (proceso de ingeniería), `tech` (herramienta específica), `business` (reglas de negocio del proyecto)

### Reglas
- Un skill = un archivo = una tecnología/herramienta/disciplina
- Los skills **no contienen lógica de negocio** — solo conocimiento técnico
- Los skills son **agnósticos al proyecto** — aplican a cualquier proyecto que use esa tecnología
- Si un skill tiene dependencias, deben estar declaradas en el frontmatter
- El `registry.md` debe actualizarse cada vez que se agrega, modifica o elimina un skill

### Cuándo crear un nuevo skill

| Criterio | ¿Crear skill? |
|----------|--------------|
| Tecnología usada en 2+ proyectos | ✅ Sí |
| Herramienta con convenciones específicas | ✅ Sí |
| Librería trivial sin configuración especial | ❌ No |
| Patrón que ya está cubierto por otro skill | ❌ No — extender el existente |
| Regla de negocio de un proyecto | ❌ No — eso va en `.ai/business-rules.md` |

---

## Cómo se Consumen los Skills

1. El **Skill Manager** (`roles/skill-manager.md`) detecta y activa los skills necesarios
2. Los agentes del pipeline consultan los skills activos antes de trabajar
3. El archivo `.ai/skills.md` del proyecto lista los skills instalados

Ver [`docs/skill-system.md`](../docs/skill-system.md) para la guía completa del ciclo de vida.

---

## Catálogo de Skills Framework (v1.1)

| Skill | Categoría | Tipo | Uso Principal |
|:---|:---|:---|:---|
| `requirements-discovery` | analysis | method | Descubrimiento de requerimientos antes del diseño |
| `ux-heuristics` | analysis | method | Evaluación y diseño de UX con heurísticas |
| `api-design` | architecture | method | Diseño de APIs RESTful |
| `backend-architecture` | architecture | method | Capas y arquitectura de servicios backend |
| `database-design` | architecture | method | Modelado de datos, índices y migraciones |
| `performance-tuning` | architecture | method | Optimización de rendimiento |
| `ai-integration` | architecture | method | Integración de IA/LLMs como componente |
| `code-review` | development | method | Revisión de código y PRs |
| `frontend-patterns` | development | method | Componentes y arquitectura frontend |
| `mobile-development` | development | method | Apps móviles y offline-first |
| `test-strategy` | qa | method | Pirámide de pruebas y estrategia |
| `testing-automation` | qa | method | Automatización de tests y CI |
| `security-audit` | qa | method | Auditoría de seguridad |
| `release-readiness` | workflow | method | Checklist pre-lanzamiento |
| `devops-pipeline` | workflow | method | Diseño de CI/CD y entornos |

---

*Skills versión 1.0 — ai-agents library | github.com/ezequielmendoza-dev/ai-agents*
