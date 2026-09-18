# Instrucciones para GitHub Copilot — Abbia OS

> **Importante:** Este archivo contiene instrucciones específicas para GitHub Copilot bajo **Abbia OS**.
> Para la guía completa de roles, workflows y reglas documentales, consultar `AGENTS.md` en la raíz del proyecto.
> **Lema de Abbia:** *Layered Context, Structured Memory, Autonomous Delivery.*

---

## 📋 Comportamiento General

1. **Leer contexto antes de actuar.** Comenzar leyendo `.abbia/context.md` y `.abbia/memory/context-snapshot.md`.
2. **Seguir el sistema de agentes.** Consultar `AGENTS.md` para conocer los roles, workflows y reglas documentales.
3. **Adoptar el rol correcto.** Según la fase de la tarea actual, leer y actuar conforme al rol en `.abbia/core/roles/`.
4. **Respetar la jerarquía documental.** No crear documentos fuera de `.abbia/initiatives/FEAT-NNN-slug/` salvo actualización de documentos permanentes.
5. **Cierre Mandatorio de Fase (Regla R6).** Al finalizar cualquier entrega o fase de trabajo, **ejecutar en terminal**: `bash .abbia/core/scripts/finish-phase.sh <INICIATIVA> <FASE> <ROL> --model <MODELO> --tokens-in <IN> --tokens-out <OUT> --duration <S> --source measured` (o `./abbia finish ...`).

---

## ⚙️ Reglas Específicas de GitHub Copilot

### Copilot Chat
- Cuando el usuario pregunte sobre la arquitectura o reglas de negocio, citar directamente los documentos permanentes de `.abbia/`.
- Para preguntas sobre implementación, consultar primero `.abbia/architecture.md` y las convenciones en `.abbia/context.md`.
- Si se solicita una explicación de código existente, considerar el contexto del módulo y su rol dentro de la arquitectura.

### Autocompletado Inline
- Respetar las convenciones de naming definidas en `.abbia/context.md`:
  - Archivos: `kebab-case`
  - Clases: `PascalCase`
  - Variables: `camelCase`
  - Constantes: `SCREAMING_SNAKE_CASE`
- Mantener el estilo del código circundante (indentación, comillas, punto y coma).
- Priorizar patrones ya establecidos en el proyecto sobre patrones genéricos.

### Copilot para Pull Requests
- Al generar descripciones de PR, seguir el formato:
  - **Qué:** Descripción del cambio.
  - **Por qué:** Contexto y motivación (referenciar `FEAT-NNN` o `BUG-NNN`).
  - **Cómo:** Detalle técnico breve de la implementación.
- Al revisar código en PRs, validar contra los checklists relevantes en `.abbia/core/checklists/`.

### Workspace Agent (@workspace)
- Cuando el usuario use `@workspace`, priorizar el contexto en este orden:
  1. `.abbia/context.md`
  2. `.abbia/memory/context-snapshot.md`
  3. `.abbia/architecture.md`
  4. `.abbia/business-rules.md`
  5. El código fuente relevante a la pregunta.
