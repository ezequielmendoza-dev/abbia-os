# Agents

Definiciones de los agentes del sistema. Cada agente tiene un rol específico, restricciones claras y un formato de output estructurado.

---

## Agentes del Pipeline Principal

Estos agentes forman el flujo estándar de desarrollo. Se usan en orden.

| Archivo | Rol | Posición en el pipeline |
|---------|-----|------------------------|
| [`analyst.md`](analyst.md) | Product Analyst | 1° — Especificaciones funcionales |
| [`ui-designer.md`](ui-designer.md) | UI Designer | 2° — Diseño visual y de interfaz (UI/UX) |
| [`architect.md`](architect.md) | Software Architect | 3° — Diseño técnico |
| [`tech-lead.md`](tech-lead.md) | Tech Lead | 4° / Supervisor — Revisión y decisiones |
| [`developer.md`](developer.md) | Senior Developer | 5° — Implementación |
| [`qa.md`](qa.md) | QA Engineer | 6° — Validación y calidad |

## Agentes de Soporte

Estos agentes se activan bajo demanda, no siguen el pipeline estándar.

| Archivo | Rol | Cuándo activarlo |
|---------|-----|-----------------|
| [`skill-manager.md`](skill-manager.md) | Skill Manager | Orquestación, descubrimiento de skills, resolución de conflictos, recomendación de skills externas |
| [`devops.md`](devops.md) | DevOps Engineer | CI/CD, deployments, setup de entornos, incidentes |

---

## Recursos

- **Framework Skills:** [`../skills/`](../skills/) — Skills metodológicas invocadas según la tarea (UX, testing, seguridad…)
- **Guía de prompts:** [`prompt-guide.md`](prompt-guide.md) — Cómo activar cada agente efectivamente
- **Definición de estructura:** [`../docs/agent-definitions.md`](../docs/agent-definitions.md) — Estándar que siguen todos los agentes
- **Templates de output:** [`../templates/`](../templates/) — Archivos de referencia para los outputs

---

## Versiones

Todos los agentes están en versión **3.0**.
Ver [`../CHANGELOG.md`](../CHANGELOG.md) para el historial de cambios.

---

*ai-agents library v3.2.0 | [github.com/ezequielmendoza-dev/ai-agents](https://github.com/ezequielmendoza-dev/ai-agents)*
