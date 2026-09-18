# Filosofía SDD — Specification-Driven Development

> **Versión:** 1.0  
> **Estado:** Vigente  
> **Última actualización:** Julio 2026

---

## El Modelo Mental Central

> **Los documentos son la fuente de verdad. Los agentes son transformadores de conocimiento.**

`ai-agents` implementa **Specification-Driven Development (SDD)**: un modelo de trabajo donde cada pieza de conocimiento —funcional, visual, técnica— existe como un artefacto escrito antes de que cualquier código se produzca.

Los agentes no son el objetivo. Son los mecanismos que producen, refinan y validan esos artefactos.

---

## Por Qué SDD

El desarrollo asistido por IA tiene un problema estructural: la IA trabaja sobre contexto conversacional, que es efímero, no verificable y no reutilizable. Una buena conversación con la IA produce código. Una mala conversación produce deuda técnica invisible.

SDD resuelve esto al desplazar la fuente de verdad desde la conversación hacia los documentos:

| Sin SDD | Con SDD |
|---------|---------|
| La IA "recuerda" el requerimiento de la conversación | El requerimiento vive en `spec.md`, permanentemente |
| El diseño técnico está en el chat | El diseño está en `architecture.md`, revisable y versionable |
| Los criterios de aceptación están implícitos | Están en `spec.md`, verificables por cualquier agente |
| El razonamiento detrás de las decisiones se pierde | Está en `discovery.md` y `decisions.md` |
| Cambiar de sesión o de IDE reinicia el contexto | Los documentos persisten entre sesiones, IDEs y personas |

---

## El Flujo Centrado en Artefactos

```
[Idea]
  ↓
[discovery.md]       ← Analyst explora, detecta ambigüedades, propone alternativas
  ↓
[spec.md]            ← Analyst formaliza la Feature Specification
  ↓
[ui-design.md]       ← UI Designer diseña la interfaz a partir de la spec
  ↓
[architecture.md]    ← Architect diseña la solución técnica
  ↓
[Implementación]     ← Developer implementa consumiendo los documentos anteriores
  ↓
[qa.md]              ← QA valida contra spec.md + architecture.md
  ↓
[Knowledge Update]   ← Documentos permanentes (.ai/) actualizados si corresponde
```

**Cada agente consume el documento producido por el agente anterior — no el contexto conversacional.**

Esto garantiza que el pipeline es reproducible: si se cambia de sesión, de IDE o de agente, el trabajo puede retomarse desde el documento más reciente sin pérdida de contexto.

---

## Los Tres Tipos de Artefactos

### 1. Artefactos de Discovery

Capturan el razonamiento y las decisiones *previas* a la especificación formal.

- `discovery.md` — Preguntas respondidas, alternativas evaluadas, justificación funcional
- `decisions.md` (en `.ai/`) — Decisiones arquitectónicas y técnicas permanentes del proyecto

**Regla:** El razonamiento detrás de cada decisión debe poder reconstruirse leyendo estos documentos.

### 2. Artefactos de Especificación

Definen *qué* se construirá y *cómo se verá y se comportará* antes de que el código exista.

- `spec.md` — Especificación funcional: actores, casos de uso, reglas de negocio, criterios de aceptación
- `ui-design.md` — Especificación visual: layouts, componentes, estados, adaptabilidad

**Regla:** Ningún agente técnico (Architect, Developer) puede comenzar a trabajar sin una spec aprobada.

### 3. Artefactos de Implementación

Definen *cómo* se construirá y *qué* calidad tiene lo construido.

- `architecture.md` — Diseño técnico: entidades, APIs, flujos, riesgos
- `qa.md` — Reporte de validación: cobertura de criterios, bugs, resultado final

**Regla:** La implementación nunca modifica los artefactos de especificación — si hay un conflicto, se escala al Tech Lead.

---

## Los Agentes como Transformadores

Cada agente tiene una responsabilidad única: tomar el artefacto previo y producir el siguiente.

```
Analyst      → transforma [Idea + contexto] en [discovery.md] y [spec.md]
UI Designer  → transforma [spec.md] en [ui-design.md]
Architect    → transforma [spec.md + ui-design.md] en [architecture.md]
Developer    → transforma [architecture.md] en [código]
QA Engineer  → transforma [código + spec.md] en [qa.md]
Tech Lead    → valida cada transformación y autoriza el avance
```

Los agentes no acumulan conocimiento entre sí a través de la conversación. Lo acumulan a través de los documentos.

---

## La Regla de Contexto Mínimo

Un agente bien activado en SDD necesita:

1. **Su definición de rol** (`roles/[agente].md`)
2. **El documento permanente del proyecto** (`.ai/context.md`, `.ai/architecture.md`, etc.)
3. **El artefacto de la feature actual** (el documento que debe consumir o producir)

Nada más. Cualquier información no contenida en estos tres inputs debe ser explícitamente solicitada o inferida — nunca asumida del contexto conversacional.

---

## La Promesa del Framework

Un proyecto que sigue SDD con `ai-agents` puede:

- Retomar trabajo después de días, semanas o meses sin perder contexto
- Cambiar de IDE o de asistente de IA sin retrabajo
- Incorporar un nuevo colaborador que puede leer el estado completo de la feature en sus documentos
- Auditar por qué se tomó cada decisión leyendo `discovery.md` y `decisions.md`
- Validar automáticamente que ningún documento está desactualizado

---

## Lecturas Relacionadas

- [`docs/documentation-strategy.md`](documentation-strategy.md) — Las 5 Reglas Documentales
- [`docs/artifact-lifecycle.md`](artifact-lifecycle.md) — Ciclo de vida de los artefactos
- [`docs/project-ai-structure.md`](project-ai-structure.md) — Estructura `.ai/` del proyecto

---

*Filosofía SDD v1.0 — ai-agents framework | github.com/ezequielmendoza-dev/abbia-os*
