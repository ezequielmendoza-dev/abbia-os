---
id: testing-automation
category: qa
aliases: [test-automation, ci-testing, automated-tests]
type: method
version: 1.0
---

# Testing Automation

> Metodología para automatizar pruebas de forma sostenible: marcos de trabajo, granularidad, selectividad y confiabilidad de la suite.

---

## Cuándo Usar Esta Skill
- Al automatizar pruebas de una funcionalidad nueva o existente.
- Al escribir tests que deben correr en CI de forma fiable.
- Al diagnosticar una suite de tests lenta o frágil (flaky).

## Principios Fundamentales
1. **Cada Test Debe Fallar por Una Razón:** Un test que verifica al mismo tiempo comportamiento, formato y detalle de implementación es difícil de diagnosticar.
2. **Tests que Simulan al Usuario, no a la Implementación:** Para frontend, interactuar con lo que el usuario ve (roles, texto, labels) antes que con detalles internos de estado.
3. **Confianza sobre Cobertura:** Una suite pequeña y estable que cubre los flujos críticos vale más que una gigante con flakiness.

## Niveles de Automatización

### Unit Tests
- Rapidez extrema (< 100ms por test), sin I/O externo.
- Mockear dependencias externas en el límite de la unidad.
- Cubrir lógica pura, cálculos, parsers, transformaciones.

### Component/Integration Tests
- Montar componentes/funciones con sus dependencias reales (repo de test, HTTP fake).
- Verificar flujos de estado: éxito, error, empty, loading.
- Usar bases de datos en memoria o testcontainers para aislamiento.

### E2E Tests
- Solamente flujos dorados (login, checkout, CRUD principal, onboarding).
- Simular al usuario real (Playwright/Cypress), no llamar funciones internas.
- Marcar con tags (`@smoke`, `@critical`) para poder ejecutar subconjuntos en CI.

## Confiabilidad de la Suite (Anti-Flakiness)

- **Determinismo:** Sin dependencia de tiempo real, red o estado global entre tests. Eliminar `sleep()`; usar esperas explícitas sobre condiciones.
- **Aislamiento:** Cada test debe limpiar o crear su propio estado. Nunca depender del orden de ejecución de otros tests.
- **Selectores estables:** Preferir `data-testid` o roles accesibles; evitar selectores anclados a clases CSS o posiciones de DOM.
- **Retry selectivo:** Para E2E con dependencia de red, retry controlado solo en infraestructura, no ennamascarar bugs lógicos.

## Estrategia en CI

- **Pirámide invertida por velocidad:** Correr unit primero (rápidos), luego integration, luego E2E (lentos). Cortar temprano si falla una capa inferior.
- **Selectividad por cambio:** En PRs, correr los tests de las áreas impactadas; en `main`, la suite completa.
- **Paralelización:** Split de tests por worker para E2E. Cache de artefactos (node_modules, caches de build).
- **Reportes de fallo accionables:** Screenshots/videos en E2E, logs de la traza en integration.

## TDD como Herramienta, no como Dogma
- Para lógica compleja y propensa a errores, red-green-refactor es valioso.
- Para UI exploratoria o prototipos, escribir tests después del feedback visual es aceptable.
- La deuda de testing no pagada se acumula: cada bug no cubierto por un test es una invitación a regresionar.

## Anti-Patrones
- ❌ **Snapshot tests frágiles::** AP: snapshots gigantes que se rompen con cualquier cambio de estilo y que nadie revisa. Usarlos solo para estructuras estables y revisar el diff siempre.
- ❌ **Testear el mock, no el código:** Mocks demasiado detallados que hacen que el test pase sin verificar la lógica real.
- ❌ **E2E para todo:** Duplicar la cobertura de unit en E2E ralentiza la suite sin aportar confianza.
- ❌ **Tests que dependen del orden:** Compartir estado entre tests (singletons, BD global mutable).
- ❌ **Ignorar tests que fallan:** Dejar `skip()` o `only()` accidentalmente en el código, o tests que fallan "porque hoy no" sin investigar.

## Integración con Otros Skills
- Se complementa con [`test-strategy`](test-strategy.md) (el *qué* y *cuánto* probar) y [`testing-automation`](testing-automation.md) (el *cómo* automatizar).
- Con [`devops-pipeline`](../workflow/devops-pipeline.md) para integrar la suite en el pipeline de CI/CD.
- Con [`frontend-patterns`](frontend-patterns.md) para selectores y granularidad de tests de componentes.