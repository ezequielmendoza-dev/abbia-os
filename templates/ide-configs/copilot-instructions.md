# Instrucciones para GitHub Copilot — ai-agents OS

> **Importante:** Este archivo contiene instrucciones específicas para GitHub Copilot.
> Para la guía completa de roles, workflows y reglas documentales, consultar `AGENTS.md` en la raíz del proyecto.

---

## 📋 Comportamiento General

1. **Leer contexto antes de actuar.** Siempre comenzar leyendo `.ai/context.md` para entender el proyecto.
2. **Seguir el sistema de agentes.** Consultar `AGENTS.md` para conocer los roles, workflows y reglas documentales.
3. **Adoptar el rol correcto.** Según la fase de la tarea actual, leer y actuar conforme al archivo del rol correspondiente en `.ai/agents/roles/`.
4. **Respetar la jerarquía documental.** No crear documentos fuera de `.ai/features/FEAT-NNN-slug/` salvo actualización de documentos permanentes.
5. **Cierre Mandatorio de Fase (Regla R6).** Al finalizar cualquier entrega o fase de trabajo, **ejecutar en terminal**: `bash .ai/agents/scripts/finish-phase.sh <INICIATIVA> <FASE> [ROL]`.

---

## ⚙️ Reglas Específicas de GitHub Copilot

### Copilot Chat
- Cuando el usuario pregunte sobre la arquitectura o reglas de negocio, citar directamente los documentos permanentes de `.ai/`.
- Para preguntas sobre implementación, consultar primero `.ai/architecture.md` y las convenciones en `.ai/context.md`.
- Si se solicita una explicación de código existente, considerar el contexto del módulo y su rol dentro de la arquitectura.

### Autocompletado Inline
- Respetar las convenciones de naming definidas en `.ai/context.md`:
  - Archivos: `kebab-case`
  - Clases: `PascalCase`
  - Variables: `camelCase`
  - Constantes: `SCREAMING_SNAKE_CASE`
- Mantener el estilo del código circundante (indentación, comillas, punto y coma).
- Priorizar patrones ya establecidos en el proyecto sobre patrones genéricos.

### Copilot para Pull Requests
- Al generar descripciones de PR, seguir el formato:
  - **Qué:** Descripción del cambio.
  - **Por qué:** Contexto y motivación (referenciar `FEAT-NNN` o `BUG-NNN` si aplica).
  - **Cómo:** Detalle técnico breve de la implementación.
- Al revisar código en PRs, validar contra los checklists relevantes en `.ai/agents/checklists/`.

### Workspace Agent (@workspace)
- Cuando el usuario use `@workspace`, priorizar el contexto en este orden:
  1. `.ai/context.md`
  2. `.ai/architecture.md`
  3. `.ai/business-rules.md`
  4. El código fuente relevante a la pregunta.
