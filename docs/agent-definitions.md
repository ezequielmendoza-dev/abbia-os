# Agente: Definición Base

> **Uso:** Meta-documento. Define la estructura estándar que todo agente debe seguir.  
> **Ubicación:** `docs/agent-definitions.md`  
> **Referenciado por:** Todos los agentes en `roles/`

---

## Estructura Estándar de un Agente

Todo agente en este repositorio sigue esta estructura:

```markdown
# [Nombre del Agente]

> Versión, rol en el pipeline, agente anterior/siguiente, template de salida

## Role
Quién es el agente. Su experiencia y perspectiva.

## Mission
Qué debe lograr. Los atributos de calidad de su output.

## Responsibilities
Qué debe hacer, organizado en categorías.

## Constraints
Qué NO debe hacer. Lista explícita con ❌ y ✅.

## Inputs
Qué información puede recibir para trabajar.

## Chain of Thought
Pasos de razonamiento interno antes de responder.

## Output Format
Estructura exacta de la respuesta, con ejemplos reales.

## Cómo Activar Este Agente
Prompt de activación, señales de cuándo usarlo y cuándo no.
```

---

## Principios de Diseño de Agentes

### 1. Separación estricta de roles
Cada agente tiene un dominio claro. Los constraints definen los límites — son tan importantes como las responsabilidades.

### 2. Chain of Thought explícito
Los agentes razonan antes de responder. El Chain of Thought guía ese razonamiento interno para producir outputs de mayor calidad.

### 3. Output determinístico
El formato de salida es fijo y estructurado. Esto permite que los outputs de un agente sean el input de otro, creando un pipeline predecible.

### 4. Activación explícita
Cada agente define exactamente cuándo debe y no debe ser usado. Esto evita usar el agente equivocado para la tarea equivocada.

### 5. Versionado
Los agentes tienen versión explícita. Cuando se mejoran, la versión se incrementa para mantener trazabilidad.

---

## Pipeline de Agentes

```
[Idea / Requerimiento]
        ↓
   analyst.md          → feature-spec.md
        ↓
   architect.md        → architecture-spec.md
        ↓
   tech-lead.md        → review (aprueba / rechaza / redirige)
        ↓
   developer.md        → implementación + technical-task.md
        ↓
   qa.md               → qa-report.md
        ↓
   tech-lead.md        → veredicto final
        ↓
   [Producción]
```

---

## Versionado de Agentes

| Versión | Cambio |
|---------|--------|
| `1.0` | Versión inicial — estructura básica |
| `2.0` | Chain of Thought, Output Format estructurado, guías de activación |

---

*Meta-documento versión 2.0 — ai-agents library | github.com/ezequielmendoza-dev/abbia-os*
