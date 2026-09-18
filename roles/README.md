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

## 🧠 Asignación de Modelos de IA Recomendados (Tiered Models)

Para maximizar la calidad de los artefactos y optimizar el consumo de tokens/costos, se recomienda asignar los tiers de modelos de IA según la complejidad cognitiva del rol:

| Rol | Tier Recomendado | Modelos de Ejemplo | Justificación |
| :--- | :--- | :--- | :--- |
| **Product Analyst** | **Reasoning / Pro** | Claude 3.7 Sonnet (Thinking), GPT-4o / o3, Gemini 2.5 Pro | Descubrimiento de casos borde y ambigüedades funcionales. |
| **UI Designer** | **Visual / Multimodal** | Claude 3.7 Sonnet, GPT-4o | Comprensión espacial, sistemas de diseño y análisis de capturas. |
| **Software Architect** | **High Reasoning / Pro** | o3, Claude 3.7 Sonnet (Extended Thinking), Gemini Pro | Modelado de ADRs, consistencia de datos y análisis de impacto en KG. |
| **Tech Lead** | **Reasoning / Pro** | o3, Claude 3.7 Sonnet, Gemini Pro | Gatekeeper crítico, auditoría cruzada y detección de riesgos. |
| **Senior Developer** | **Balanced / Code** | Claude 3.7 Sonnet / Sonnet 3.5, GPT-4o, Gemini 2.5 Flash | Generación de código preciso, tipado estricto y pruebas unitarias. |
| **QA Engineer** | **Balanced / Code** | Claude Sonnet, GPT-4o, Gemini Flash | Ejecución y análisis adversarial de pruebas y suites de test. |
| **DevOps Engineer** | **Fast / Standard** | Claude Sonnet / Haiku, GPT-4o mini, Gemini Flash | Scripts de despliegue, YAMLs y CI/CD pipelines. |
| **Skill Manager** | **Fast / Lite** | Gemini Flash, Claude Haiku, GPT-4o mini | Compactación de memoria, snapshots (<50 líneas) y descubrimiento. |

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

*ai-agents library v3.3.0 | [github.com/ezequielmendoza-dev/abbia-os](https://github.com/ezequielmendoza-dev/abbia-os)*
