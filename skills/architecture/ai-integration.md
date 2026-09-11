---
id: ai-integration
category: architecture
aliases: [ai, llm, ml-integration]
type: method
version: 1.0
---

# AI Integration

> Metodología para integrar capacidades de IA (LLMs, embeddings, voz, visión) en productos de software: arquitectura, costos, determinismo y evaluación.

---

## Cuándo Usar Esta Skill
- Al diseñar una funcionalidad que usa LLMs o modelos de ML dentro de un producto.
- Al analizar el costo/valor de introducir IA en un flujo existente.
- Al preparar una feature de IA para producción con calidad y observabilidad.

## Principios Fundamentales
1. **IA como Componente, no como Misterio:** El LLM es una función con contrato (entrada/estructura de salida) como cualquier otra dependencia; debe estar tras una interfaz.
2. **Determinismo donde Importa, Creatividad donde Ayuda:** La magia de la IA no reemplaza el control del flujo. Los caminos críticos de negocio son deterministas (validación, pagos, permisos); la IA aporta donde el lenguaje abierto es el dominio.
3. **LLMs Cometen Errores con Confianza:** Todo output generativo pasa por validación, clasificación de confianza y fallback. Nunca confiar el dato correcto por defecto de un modelo no verificado.

## Arquitectura de Integración

```
┌────────────┐  ┌───────────────┐  ┌──────────────────┐  ┌─────────────┐
│  Feature   │→│  AI Service   │→│  Model Gateway   │→│  Provider   │
│  (UI/API)  │ │  (prompts,    │ │  (routing, cache, │ │  (GPT, gemini,│
│            │←│  contracts,    │←│   retry, fallback)│←│   claude)|   │
└────────────┘  └───────────────┘  └──────────────────┘  └─────────────┘
```

- **AI Service (facade):** La feature habla con esta capa con tipos fuertes; nunca con el provider directamente. Habilita testes, mockeo y evolución del modelo detrás.
- **Model Gateway:** Centraliza autenticación, rate limiting, cache de respuestas, retry/fallback entre providers y telemetría de costos.
- **Compatibilidad de contrato:** Structured output (JSON Schema/Zod) para que la salida sea parseable; con repair/retry si no cumple.

## El Prompt como Contracto

- **System Prompt vs. User Input:** El system prompt es código (versionado, testeado, auditado). El user input es dato no confiable, nunca se concatena sin sanitizar.
- **Few-shot de calidad:** Los ejemplos definen el formato de salida más que cualquier instrucción. Pocos ejemplos, variados y con casos borde.
- **Inyección de prompt:** Input del usuario puede intentar reescribir instrucciones. Aislar datos, delimitarlos y tratar el contenido como no confiable (igual que SQL injection).

## Evaluación de Calidad

| Aspecto | Método |
|:---|:---|
| Exactitud de salida | Golden dataset (inputs + outputs esperados), eval over CI |
| Formato | Validación de schema (Zod/Pydantic) con retry/repair |
| Alucinación | Grounding: chequear hechos contra fuentes reales; pedir citas |
| Calidad percibida | Feedback de uso, thumbs/rating, revisión por humanos muestreada |
| Deriva | Testset re-ejecutado en cada cambio de prompt/modelo |

- **Prompt Eval en CI:** Añadir un testset de ~20-50 casos que corra en cada PR que toque el prompt o el modelo. Regresión == PR bloqueado.

## Costos y Observabilidad

- **Medir Tokens como Costo Real:** Cada llamada loggear: modelo, tokens in/out, latencia, costo. El gasto de IA crece silenciosamente sin telemetría.
- **Cache de prompts repetidos:** LLM caching o cache de respuestas para queries idénticas en cargas altas.
- **Rutas de costo:** Modelos pequeños/baratos para alta frecuencia (clasificación), modelos grandes solo para casos complejos.
- **Budget caps:** Límites por usuario/feature/día con bloqueo frente a abuso (un usuario que consume el presupuesto).

## Multi-Modal sin Multisasia

- **Visión:** Archivos de imagen/PDF → extracción estructurada. Validar que el modelo pueda fallar.
- **Voz:** Transcripción (ASR) → generación (TTS). Ambos son modelos: medir latencia total y calidad.
- **Embeddings/RAG:** Chunks bien delimitados, retrievers evaluados por exactly retrieval@k; contexto inyectado con límites claros.

## Anti-Patrones
- ❌ **Usar IA donde no aporta:** Añadir un LLM a flujos que una regex o un select con data estática resuelven mejor, más barato y más determinist. ($ = latencia + cost + riesgo).
- ❌ **Confiar la salida sin validación:** Escribir directo a BD o ejecutar acciones basadas en output no validado del modelo.
- ❌ **Prompt gigante no versionado:** 5k tokens de instrucciones solo en el chat sin test ni version → inmanejable y non-reproducible.
- ❌ **Ignorar fallos:** El modelo da un JSON rotó una vez cada 100 y el sistema crashea. Validación + retry + fallback.
- ❌ **Exponer la API de un provider directamente:** Sin gateway ni facade, cambiar de provider o de modelo es una reescritura total y el costo es inexplicable.
- ❌ **Sin consideración de privacidad:** Mandar PII a un provider externo sin política de retención ni consentimiento.

## Integración con Otros Skills
- Define el contrato de datos servido por [`backend-architecture`](backend-architecture.md).
- Con [`security-audit`](../qa/security-audit.md) para inyección de prompt y datos.
- Con [`performance-tuning`](performance-tuning.md) para latencia de inferencia y caché.
- Con [`test-strategy`](../qa/test-strategy.md) para la evaluación (eval/testset) dentro de la estrategia de calidad.