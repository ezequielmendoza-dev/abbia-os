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

| Métrica / Dimensión | Tipo / Unidad | Descripción |
|:---|:---|:---|
| `tokens_in` | entero (tokens) | Entrada consumida por el agente en la invocación |
| `tokens_out` | entero (tokens) | Salida producida por el agente |
| `tokens_total` | entero (tokens) | `tokens_in + tokens_out` |
| `duration_s` | entero (segundos)| Tiempo transcurrido desde activación hasta cierre del agente |
| `phase` | string | Fase del DAG (ej. `discovery`, `implement`, `qa`, `deploy`) |
| `role` | string | Agente en ejecución (`analyst`, `developer`, `qa`, `architect`, etc.) |
| `model` | string | Identificador del modelo de IA (ej. `claude-3-7-sonnet`, `deepseek-r1`, `gemini-2.5-pro`) |
| `provider` | string | IDE o cliente ejecutor (ej. `opencode`, `antigravity`, `cursor`, `claude-code`) |
| `target_env` | enum | Entorno de validación/ejecución (`local`, `staging`, `production`) |
| `git_branch` | string | Rama activa de Git durante la ejecución (ej. `main`, `feat/042-slug`) |
| `attempts` | entero | Nº de intentos del nodo (back-edge con `retry`) |
| `verdict` | enum | Resultado del gate (`APROBADO`, `RECHAZADO`, `PASS`, `FAIL`), si aplica |
| `source` | enum | Origen del dato (`measured` si proviene de API/IDE, `estimate` si es heurístico) |

**Métricas y Agregados Derivados:**
- **Costo Dinámico en USD (OpenRouter Live Pricing):** El dashboard consulta en tiempo real `https://openrouter.ai/api/v1/models` para tarificar con cero hardcoding:
  $$\text{Costo USD} = \frac{\text{tokens\_in} \times \text{Tarifa In}}{10^6} + \frac{\text{tokens\_out} \times \text{Tarifa Out}}{10^6}$$
- **Consumo por Modelo y Proveedor:** Permite comparar el ROI y eficiencia de distintos LLMs e IDEs.
- **Distribución por Entorno:** Visibilidad de qué fases se validaron en `local`, `staging` o `production`.
- **Eficiencia de tokens:** `tokens_out / tokens_total` (fracción útil de generación).
- **Tasa de retry:** `Σ (attempts - 1)` por fase (proxy de calidad del gate anterior).

---

## 3. Ubicación, Formato y Visualización
 
Las métricas viven en `.abbia/metrics/`, separadas de la memoria cualitativa (`.abbia/memory/`):

```
.abbia/metrics/
├── README.md               ← Contrato de uso (este sistema, copiado al proyecto)
├── executions.yaml         ← Registro append-only por ejecución de agente
└── aggregates.yaml         ← Agregados multidimensionales (regenerado automáticamente)
```

### Visualización con el Dashboard & Live Server
Las métricas se pueden visualizar de forma interactiva ejecutando:
- `./abbia dashboard` — Genera y abre `.abbia/dashboard.html` en el navegador (se auto-regenera silenciosamente tras cada cierre de fase).
- `./abbia serve [PORT]` — Inicia un servidor web local con **Live Reload** en tiempo real (recarga automática al guardar cambios).
- `./abbia watch` — Vigila cambios en segundo plano y auto-regenera el HTML.


### `executions.yaml` — registro bruto (append-only)

Generado/append por cada agente al cerrar (`finish-phase.sh`), o por el orquestador (Skill Manager). **Nunca se reescribe una entrada previa.**

```yaml
executions:
  - ts: 2026-09-16T15:30:00Z
    initiative: FEAT-042
    role: developer
    phase: implement
    mode: estandar
    model: deepseek/deepseek-r1
    provider: opencode
    target_env: local
    git_branch: feat/042-pagos
    tokens_in: 24500
    tokens_out: 6200
    duration_s: 812
    attempts: 1
    verdict: null
    source: measured

  - ts: 2026-09-16T16:02:00Z
    initiative: FEAT-042
    role: qa
    phase: qa
    mode: estandar
    model: anthropic/claude-3.7-sonnet
    provider: opencode
    target_env: staging
    git_branch: feat/042-pagos
    tokens_in: 18000
    tokens_out: 4100
    duration_s: 430
    attempts: 1
    verdict: APROBADO
    source: measured
```

Reglas de escritura:

1. **Una ejecución = una entrada.** Cada invocación de un agente sobre un nodo del DAG.
2. **Siempre con `ts` ISO-8601** y `initiative` (`FEAT-NNN` / `BUG-NNN`).
3. **Inferencia automática de entorno:** `finish-phase.sh` deduce `target_env: local` para diseño/código, `staging` para QA y `production` para deploy.
4. **Auto-detección de Git:** Se registra la rama activa (`git_branch`) para total trazabilidad.
5. **Los `verdict` se completan si la fase es un gate** (`qa`, `approval`, `tech-review-N`).

### `aggregates.yaml` — agregados multidimensionales (regenerado)

```yaml
generated_at: 2026-09-16T16:30:00Z
summary:
  total_executions: 94
  total_tokens_in: 1420500
  total_tokens_out: 395000
  total_tokens: 1815500
  total_duration_s: 48920
per_phase:
  implement:   { tokens_total: 820000, duration_s: 24100, executions: 35 }
  qa:          { tokens_total: 410000, duration_s: 11200, executions: 22 }
per_role:
  developer:   { tokens_total: 820000, duration_s: 24100, executions: 35 }
  qa:          { tokens_total: 410000, duration_s: 11200, executions: 22 }
per_model:
  anthropic/claude-3.7-sonnet: { tokens_total: 980000, executions: 48 }
  deepseek/deepseek-r1:        { tokens_total: 650000, executions: 32 }
per_env:
  local:       { tokens_total: 1200000, executions: 60 }
  staging:     { tokens_total: 515500,  executions: 30 }
  production:  { tokens_total: 100000,  executions: 4 }
```

`aggregates.yaml` **no se edita a mano** — lo regenera `finish-phase.sh` o el Skill Manager al compactar.

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

Todo agente del pipeline registra su ejecución en `executions.yaml` ejecutando obligatoriamente `finish-phase.sh` con sus flags de telemetría (`--model`, `--tokens-in`, `--tokens-out`, `--duration`, `--source measured|estimate`). Si el canal del agente no expone contadores exactos, el agente debe estimar los tokens y duración en lugar de omitirlos como `null`.

> **Automatización:** `scripts/finish-phase.sh` registra la ejecución (con `source: measured` o `source: estimate`), deduciendo el entorno y rama activa, junto con la entrada de `workflow-log.md` y la regeneración del snapshot.

### Fase 2 — Agregar (al final de sesión, Skill Manager)

1. Lee `executions.yaml` y agrupa por `phase`, `role` e `initiative`.
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
| **Todos los del pipeline** | Ejecutar obligatoriamente `finish-phase.sh` pasando `--model`, `--tokens-in`, `--tokens-out`, `--duration` y `--source` (Regla R6) |
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