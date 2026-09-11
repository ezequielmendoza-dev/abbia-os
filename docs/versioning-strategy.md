# Estrategia de Versionado

> Cómo se versiona el repositorio `ai-agents` y sus componentes.

---

## Principios

1. **El repositorio tiene versión propia** — independiente de los proyectos que lo usan
2. **Los agentes tienen versión propia** — pueden evolucionar a distintas velocidades
3. **El versionado es semántico** — los números tienen significado
4. **Los cambios están documentados** — siempre en `CHANGELOG.md`

---

## Versionado del Repositorio (Git Tags)

El repositorio usa [Semantic Versioning](https://semver.org/) con tags de Git:

```
v[MAJOR].[MINOR].[PATCH]

Ejemplos:
  v1.0.0  — primera versión estable
  v1.1.0  — nuevos agentes o templates (no breaking)
  v1.1.1  — correcciones menores
  v2.0.0  — cambios que rompen compatibilidad o rediseño mayor
```

### Cuándo incrementar cada número

| Tipo | Cuándo | Ejemplo |
|------|--------|---------|
| **MAJOR** | Rediseño de agentes, cambios breaking en output format | v1.x.x → v2.0.0 |
| **MINOR** | Nuevo agente, nuevo template, nueva sección importante | v1.0.x → v1.1.0 |
| **PATCH** | Correcciones, mejoras de redacción, fixes de ejemplos | v1.0.0 → v1.0.1 |

---

## Versionado de Agentes

Cada agente tiene su versión declarada en el encabezado:

```markdown
> **Versión:** 3.0
```

Los agentes usan versionado de dos números `[MAJOR].[MINOR]`:

| Cambio | Versión |
|--------|---------|
| Corrección de constraint mal redactado | `3.0` → `3.1` |
| Nueva sección (ej: Chain of Thought agregado) | `2.0` → `3.0` |
| Rediseño completo del Output Format | `X.x` → `X+1.0` |

### Historial actual de versiones por agente

Todos los agentes del pipeline están alineados a la **MAJOR del framework** (`v3.x`). Cuando el framework publica una nueva MAJOR, todos los agentes la acompañan — no existe divergencia de versiones entre roles sin justificación documentada.

| Agente | Versión actual | Cambio principal manteniendo la MAJOR |
|--------|---------------|--------------------------------------|
| `analyst.md` | `3.0` | Spec-Driven: discovery + consumo de artefactos |
| `architect.md` | `3.0` | Spec-Driven: ADR + consumo de artefactos |
| `tech-lead.md` | `3.0` | Decision Framework + veredictos formales + gates |
| `developer.md` | `3.0` | Spec-Driven: consumo de artefactos |
| `qa.md` | `3.0` | Clasificación de bugs + veredictos PASS/FAIL |
| `ui-designer.md` | `3.0` | Diseño con tokens + guía de activación |
| `devops.md` | `3.0` | Infraestructura, CI/CD y deployment |
| `skill-manager.md` | `3.0` | Orquestador: skills + memoria + DAG |

> **Nota:** El campo `**Versión:** \`1.0\`` que aparece dentro del *output format* de algunos agentes (ej. `ui-design.md`, `architecture.md`) se refiere a la **versión del documento de salida**, no a la versión del agente. Las versión del documento de salida evoluciona de forma semántica (PATCH) independientemente de la del agente.

---

## Versionado de Skills

Cada skill declara su versión en el **frontmatter YAML** de su archivo:

```markdown
---
id: frontend-patterns
category: development
version: 1.0
---
```

Las skills usan versionado de dos números `[MAJOR].[MINOR]` (misma semántica que los agentes):

| Cambio | Versión |
|--------|---------|
| Corrección de error en el contenido / patrón | `1.0` → `1.1` |
| Nueva sección, patrón o checklist dentro del skill | `1.x` → `2.0` |
| Cambio que rompe la interfaz de consumo (frontmatter, id, output) | `X.0` → `X+1.0` |

**Reglas:**
- El `version` se actualiza **cada vez** que se modifica el contenido del skill (R4: todo cambio se refleja en `CHANGELOG.md`).
- El catálogo en `skills/README.md` se mantiene sincronizado con la versión vigente de cada skill.
- Al publicar una MAJOR nueva del framework, los skills pueden conservar su versión interna propia — **no tienen obligación de alinearse** a la MAJOR del framework (a diferencia de los agentes). El salto de MAJOR solo ocurre si el skill en sí cambia su contrato de consumo.

---

## Proceso de Release

### 1. Preparar el release

```bash
# Asegurarse de estar en main y actualizado
git checkout main && git pull

# Verificar que no hay cambios sin commitear
git status
```

### 2. Actualizar CHANGELOG.md

```markdown
## [X.Y.Z] — YYYY-MM-DD

### Agregado
- [nuevo agente / template / doc]

### Modificado
- [qué cambió y por qué]

### Eliminado
- [qué se eliminó y por qué]

### Corregido
- [qué se corrigió]
```

### 3. Crear el tag

```bash
git add CHANGELOG.md
git commit -m "chore: prepare release vX.Y.Z"
git tag -a vX.Y.Z -m "Release vX.Y.Z — [descripción breve]"
```

### 4. Push

```bash
git push origin main
git push origin vX.Y.Z
```

---

## Estrategia de Branches

| Branch | Propósito |
|--------|-----------|
| `main` | Versión estable del repositorio |
| `develop` | Trabajo en progreso (opcional, para cambios grandes) |
| `feat/nombre` | Nueva feature o agente |
| `fix/nombre` | Corrección puntual |
| `docs/nombre` | Documentación nueva o actualizada |

Para este repositorio (solo docs, sin código compilado), es suficiente trabajar directo en `main` para cambios pequeños.

---

## Compatibilidad entre Versiones

### Para proyectos que usan ai-agents como submodule

| Versión de ai-agents | Compatibilidad |
|---------------------|----------------|
| `v2.x.x` | Output formats estables dentro de la misma MAJOR |
| `v3.x.x` | MAJOR vigente (SDD). Cambios menores no rompen contratos escalonados |
| `v3.0.0` | Breaking desde v2 — revisar CHANGELOG antes de actualizar |

### Recomendación para proyectos en producción

```bash
# Pinear a una versión específica para estabilidad
cd .ai/agents
git checkout v3.1.0

# Solo actualizar cuando hayas revisado el CHANGELOG
```

---

## Convención de Commits

Este repositorio sigue [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(agents): add devops.md agent for infrastructure tasks
fix(analyst): correct constraint about technical proposals
docs(project-integration): add troubleshooting section
chore: remove legacy v1.0 agent files from root
refactor(templates): improve feature-spec acceptance criteria section
```

| Prefijo | Cuándo usarlo |
|---------|---------------|
| `feat` | Nuevo agente, template, workflow o doc importante |
| `fix` | Corrección de error en instrucciones o ejemplos |
| `docs` | Documentación nueva o actualizada en `docs/` |
| `chore` | Tareas de mantenimiento (gitignore, CHANGELOG, etc.) |
| `refactor` | Mejora sin cambio de comportamiento |

---

*Documentación versión 1.0 — ai-agents library | [github.com/ezequielmendoza-dev/ai-agents](https://github.com/ezequielmendoza-dev/ai-agents)*
