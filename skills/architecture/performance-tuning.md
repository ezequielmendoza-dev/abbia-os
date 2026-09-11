---
id: performance-tuning
category: architecture
aliases: [performance, optimization, perf]
type: method
version: 1.0
---

# Performance Tuning

> Metodología para identificar, medir y resolver problemas de rendimiento en aplicaciones sin adivinanzas ni optimizaciones prematuras.

---

## Cuándo Usar Esta Skill
- Al diseñar sistemas con requisitos de latencia o throughput conocidos.
- Al investigar endpoints o pantallas lentas en producción.
- Al definir metas de rendimiento (SLOs) para una nueva funcionalidad.

## Principios Fundamentales
1. **Medir Antes de Optimizar:** La optimización sin datos es conjetura. Definir líneas base, perciles y replicables bajo carga.
2. **El 90% del Tiempo es el Resultado de Pocas Líneas Mojadas:** Enfocarse en los cuellos de botella reales (N+1, falta de índices, payloads gigantes), no en micro-optimizaciones.
3. **Bajo la Productividad == Mejor Latencia:** El gurú de rendimiento es el que hace menos trabajo, no el que hace el mismo trabajo más rápido.

## Metodología de Optimización

### 1. Definir Métricas de Éxito
- Métricas de usuario: latencia de percepción, p95/p99, conversión.
- Métricas del sistema: throughput (rps), CPU, memoria, I/O, garbage collection.
- Apuntar a objetivos reales (ej. aprobado. "p95 < 300ms para lecturas de catálogo").

### 2. Medir el Estado Actual
- **Backend:** APM (Datadog/New Relic/Sentry) para tiempos por endpoint, queries lentas, colas.
- **Base de datos:** `EXPLAIN ANALYZE` para las queries críticas; revisar índices y lock contention.
- **Frontend:** Lighthouse/Core Web Vitals (LCP, CLS, INP), bundle size, waterfall de red.
- **Carga:** K6/Gatling/Locust para throughput y latencia bajo presión.

### 3. Identificar el Cuello (Priorizado por Impacto)
| Síntoma | Sospechosos Frecuentes |
|:---|:---|
| API lenta | N+1 en queries, falta de índices, serialización lenta, llamadas en cadena |
| API lenta solo a veces | Lock de BD, cold cache, garbage collection, thottling |
| UI lenta | Bundle enorme, falta de lazy loading, renders redundantes |
| BD lenta | Índices faltantes, queries sin límite, deadlocks, vítimas de universal sizing |
| Todo lento bajo carga | Recurso símplemente limitado (conexiones, pool, threads) |

### 4. Aplicar la Solución y Re-medir
- Mejoras de mayor retorno: caching, índices, paginación, compresión, reducir payloads, async/batch.
- Verificar con la misma métrica y bajo la misma carga; documentar el delta.

## Caché (el arma de más alto impacto)

- **Multi-nivel:** Browser cache → CDN → application cache → database index/memoria.
- **Invalidación:** TTL corto y seguro > invalidación manual frágil. Cache-aside con invalidation explícita para datos críticos.
- **Apunte de invarianza:** Cachear solo lo que cambia raramente o tolera staleness. Nunca cachear la fuente de verdad de transacciones.
- **Cache Stampede:** Coordinar los refrescos de cache en alta concurrencia (single-flight, lock).

## Scaling Patterns

- **Vertical primero, horizontal después:** Escalar hacia arriba (más CPU/RAM) es más simple y a menudo suficiente hasta un punto.
- **Horizontal (stateless):** Replicar la capa de aplicación si es sin estado. El estado se mueve a BD/cache/message broker.
- **Asincronía:** Trabajo no crítico (emails, reportes, procesamiento pesado) va a cola/batch, fuera del request path síncrono.
- **Particionar/Estrangular:** Para lecturas/escrituras a gran escala, considerar read replicas, sharding y backpressure.

## Anti-Patrones
- ❌ **Optimización prematura:** Micro-optimizar código no medido mientras el cuello es una query sin índice.
- ❌ **Cache sin invalidación:** Datos stale que corrompen decisiones de negocio. TTL mínimo y policy explícita.
- ❌ **Payloads gigantes en API:** Devolver 2MB cuando el cliente usa 3 campos. Seleccionar campos, paginar, comprimir.
- ❌ **Síncrono innecesario:** Hacer 5 llamadas HTTP en serie al cliente cuando podrían ser 1 en batch o en paralelo.
- ❌ **Métricas de adorno:** Dashboard con métricas que nadie lee ni tiene alertas con umbrales reales.
- ❌ **Sin baseline:** No saber cuánto tardaba antes, así que no sabes si la "optimización" ganó o perdió.

## Integración con Otros Skills
- Se combina con [`database-design`](database-design.md) para índices y queries.
- Con [`frontend-patterns`](../development/frontend-patterns.md) para rendimiento de UI.
- Con [`devops-pipeline`](../workflow/devops-pipeline.md) para observabilidad y métricas en staging/producción.
- Con [`test-strategy`](../qa/test-strategy.md) para pruebas de carga automatizadas.