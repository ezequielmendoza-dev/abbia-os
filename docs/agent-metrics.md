# Métricas de Agentes — Observabilidad del Pipeline

> **Versión:** 1.0  
> **Estado:** Activo  
> **Propósito:** Rastrear **tokens consumidos por rol** y **tiempo por fase** en cada ejecución del pipeline, para detectar fases costosas, agentes ineficientes y drift de calidad en el sistema de agentes.

---

## 1. El Problema que Resuelve

El pipeline de `ai-agents` produce artefactos (specs, diseños, QA) y ahora memoria (`workflow-log.md`). Pero **no mide el costo** de producirlos:

- ¿Cuántos tokens consume un Analyst en una feature compleja vs. un Developer?
- ¿Qué fase tarda más: discovery, diseño técnico o QA?
- ¿Un agente está "rebotando" el mismo artefacto por gates (retry) y quemando tokens?
- ¿El modo `rápido` vs `estándar` realmente ahorra? ¿Cuánto?

**Con métricas:** cada ejecución de agente deja un **registro numérico** (tokens in/out, duración, fase, veredicto). El Tech Lead y el Skill Manager los agregan para tomar decisiones sobre el *sistema de agentes en sí*, no sobre el producto.

> **Inspiración:** AgEnFK (traza cuantificada por agente y fase en entornos de multi-agentes de investigación), telemetría de evaluación de ZhipuAI para agentes de agencia.

---

## 2. Qué se Mide

| Métrica | Unidad | Se registra en |
|:---|:---|:---|
| `tokens_in` | tokens | Entrada consumida por el agente en la invocación |
| `tokens_out` | tokens | Salida producida por el agente |
| `tokens_total` | tokens (`in + out`) | Derivable |
| `duration_s` | segundos | Tiempo desde activación hasta cierre del agente |
| `phase` | string | Fase del DAG (ej. `discovery`, `qa`, `tech-review-1`) |
| `attempts` | entero | Nº de intentos del nodo (back-edge con `retry`) |
| `verdict` | `PASS` \| `FAIL` \| `APROBADO` \| `RECHAZADO` | Resultado del gate, si aplica |

**Métricas agregadas (derivadas, no se escriben a mano):**
- **Costo por fase:** `Σ tokens_total` agrupado por `phase`.
- **Eficiencia de tokens:** `tokens_out / tokens_total` (qué fracción de lo consumido es útil).
- **Tiempo de ciclo:** `Σ duration_s` de una feature completa (desde discovery hasta QA gate).
- **Tasa de retry:** `Σ (attempts - 1)` por fase — un proxy de calidad del gate anterior.

---

## 3. Ubicación y Formato

Las métricas viven en `.ai/metrics/`, separadas de la memoria cualitativa (`.ai/memory/`):

```
.ai/metrics/
├── README.md               ← Contrato de uso (este sistema, copiado al proyecto)
├── executions.yaml         ← Registro append-only por ejecución de agente
└── aggregates.yaml         ← Agregados por fase/rol (regenerado, no manual)
```

### `executions.yaml` — registro bruto (append-only)

Generado/append por cada agente al cerrar, o por el orquestador (Skill Manager) que envuelve la invocación. **Nunca se reescribe una entrada previa.**

```yaml
executions:
  - ts: 2026-09-11T15:30:00Z
    initiative: FEAT-042
    role: architect
    phase: architecture
    mode: estandar
    tokens_in: 18423
    tokens_out: 5912
    duration_s: 812
    attempts: 1
    verdict: null

  - ts: 2026-09-11T16:02:00Z
    initiative: FEAT-042
    role: tech-lead
    phase: tech-review-1
    mode: estandar
    tokens_in: 7421
    tokens_out: 1804
    duration_s: 233
    attempts: 2            # 1er gate RECHAZADO → devuelto al analyst
    verdict: APROBADO
```

Reglas de escritura:

1. **Una ejecución = una entrada.** Cada invocación de un agente sobre un nodo del DAG.
2. **Siempre con `ts` ISO-8601** y `initiative` (`FEAT-NNN` / `BUG-NNN`).
3. **`attempts` refleja back-edges** — si un nodo fue devuelto 2 veces, `attempts: 3`.
4. **Los `verdict` se completan si la fase es un gate** (`tech-review-N`, `qa`, `approval`).
5. Si el agente no puede medir tokens (interfaz sin API), dejar `null` y lo estima el orquestador.

### `aggregates.yaml` — agregados (regenerado por Skill Manager)

```yaml
per_phase:
  discovery:   { tokens_total: 31240, duration_s: 1205, sample: 3 }
  architecture: { tokens_total: 24335, duration_s: 812, sample: 1 }
  qa:          { tokens_total: 9180,  duration_s: 340, sample: 2 }
per_role:
  analyst:  { tokens_total: 31240, duration_s: 1205, attempts_total: 2 }
  architect: { tokens_total: 24335, duration_s: 812, attempts_total: 1 }
  tech-lead: { tokens_total: 14842, duration_s: 466, attempts_total: 1 }
per_feature:
  FEAT-042:  { tokens_total: 122398, duration_s: 7680, retry_rate: 0.21 }
```

`aggregates.yaml` **no se edita a mano** — lo regenera el Skill Manager al compactar (mismo ciclo que `context-snapshot.md`), típicamente al final de una sesión o al superar ~20 ejecuciones.

---

## 4. Ciclo de Vida: Capturar → Agregar → Decidir

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│    CAPTURAR    │ ──▶ │    AGREGAR     │ ──▶ │    DECIDIR     │
│  Cada agente   │     │ Skill Manager  │     │ Tech Lead /    │
│  (u orquestador│     │ regenera       │     │ Skill Manager  │
│  ) escribe en  │     │ aggregates.yaml│     │ ajusta el      │
│  executions.yaml│    │ (con memoria)  │     │ sistema        │
└────────────────┘     └────────────────┘     └────────────────┘
```

### Fase 1 — Capturar (al cerrar cada agente)

Todo agente del pipeline registra su ejecución en `executions.yaml`. El **Skill Manager** es el responsable último: si el canal del agente no expone métricas, el orquestador las estima y registra (marcando `source: estimate`).

> **Automatización:** `scripts/finish-phase.sh` registra la ejecución (con `source: estimate` por defecto; `--source measured` si hay telemetría real) junto con la entrada de `workflow-log.md` y la regeneración del snapshot.

### Fase 2 — Agregar (al final de sesión, Skill Manager)

1. Lee `executions.yaml` y agrupa por `phase`, `role` y `initiative`.
2. Calcula `tokens_total`, `duration_s`, `attempts`, `retry_rate`.
3. Escribe `aggregates.yaml` (regenera, no hace append).
4. Si hay alertas (retry rate > 0.5, feature con > 150k tokens), las reporta al Tech Lead.

### Fase 3 — Decidir (Tech Lead / Skill Manager)

Las métricas alimentan decisiones del *sistema de agentes*:

| Señal | Decisión típica |
|:---|:---|
| `qa` con retry rate alto | Revisar el gate de Developer o QA (¿tests ambiguos?) |
| `discovery` > 2× el promedio | Feature mal definida; pedir clarificación antes |
| `tech-lead` consume más tokens que architect | ¿El gate está duplicando revisión? |
| Modo `rápido` ≈ `estándar` en tokens | El modo rápido no está surtiendo efecto; ajustar `truncate` |

---

## 5. Contrato de los Agentes

| Agente | Acción de métricas obligatoria |
|:---|:---|
| **Todos los del pipeline** | Registrar `executions.yaml` al cerrar (tokens, fase, duración, attempts) |
| **Skill Manager** | Orquesta `Capture → Agregar → Decidir`; regenera `aggregates.yaml`; reporta alertas |
| **Tech Lead** | Revisa `aggregates.yaml` en cada gate y decide ajustes del sistema |
| **Arquitecto (custodio)** | Las métricas no cambian el proceso documental — solo lo hacen visible |

**Regla de inferioridad:** las métricas **nunca** modifican artefactos ni versiones de agentes por sí solas — son insumo para el Tech Lead, no autoridad. Igual que la memoria, jerárquicamente por debajo de `decisions.md` y los artefactos aprobados.

---

## 6. Integración con Workflow Memory

| Memoria | Qué aporta a las métricas |
|:---|:---|
| `workflow-log.md` | El contexto cualitativo del *porqué* (decisión, motivo de retry) |
| `context-snapshot.md` | Incluye un resumen de 2-3 líneas con las métricas agregadas de la sesión previa |

Regla: **una entrada en `executions.yaml` por cada entrada en `workflow-log.md`** — las métricas cuantifican lo que la memoria narra. Si hay datos sin narración o narración sin datos, es un anti-patrón de registro.

---

## 7. Anti-Patrones

- ❌ **Métricas sin contexto:** Un número sin su entrada de memoria es ininterpretable a las 2 semanas.
- ❌ **Comparar agentes sin el modo DAG:** `profundo` siempre costará más que `rápido` — comparar solo dentro del mismo `mode`.
- ❌ **Perseguir el token más bajo:** El objetivo es *estabilidad y calidad del pipeline*, no minimizar tokens a costa de rebotes.
- ❌ **Métricas como autoridad:** `retry_rate` alto no "prueba" a un agente malo — es una señal para investigar (README de gates, ambigüedad de spec).
- ❌ **`aggregates.yaml` editado a mano:** Si vas a corregir, corrige `executions.yaml` (append con `correction:`) y deja que se regenere.

---

## 8. Referencias

- [Workflow Memory](workflow-memory.md) — la narración cualitativa de cada ejecución.
- [Workflow DAG](workflow-dag.md) — las `phase` y `attempts` provienen del DAG y sus back-edges.
- [Skill Manager](../roles/skill-manager.md) — orquestador del ciclo de métricas.
- [Tech Lead](../roles/tech-lead.md) — consumidor de las decisiones basadas en métricas.