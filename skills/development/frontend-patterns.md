---
id: frontend-patterns
category: development
aliases: [frontend, ui-development, frontend-best-practices]
type: method
version: 1.0
---

# Frontend Patterns

> Metodología para diseñar e implementar interfaces de usuario web modernas con componentes mantenibles, accesibles y de alto rendimiento.

---

## Cuándo Usar Esta Skill
- Al implementar componentes de UI o páginas en cualquier framework frontend (React, Vue, Svelte, Angular).
- Al definir la arquitectura de componentes de una nueva aplicación web.
- Al revisar la calidad de una implementación frontend existente.

## Principios Fundamentales
1. **Componentes Componibles:** Diseñar componentes orientados a composición (slots, children) en lugar de componentes monolíticos con 50 props booleanas.
2. **Separación de Preocupaciones:** Mantener la capa de datos (hooks, stores), la presentación (componentes) y el estado de UI en capas claramente separadas.
3. **Estado Mínimo Derivado:** En React/Vue/Svelte, derivar estado computable (filtrado, ordenamiento) en vez de duplicarlo en estado mutable.

## Patrones de Componentes

- **Estado de Presentación vs. Estado de Dominio:** El estado de UI (modal abierto, tab activa) vive en el componente; el estado de dominio (usuarios, items del carrito) vive en el store/contexto global.
- **Composición sobre Configuración:** Preferir `Slot`/`children`/`render prop` antes que props booleanas como `showIcon`, `isLarge`.
- **Custom Hooks:** Extraer lógica reutilizable (fetch, debounce, form handling) en hooks propios antes de copiar la misma lógica entre componentes.
- **Separación Container/Presentational:** Componentes de presentación reciben datos por props y emiten eventos; los containers manejan estado, fetching y handlers.

## Buenas Prácticas de Estilo
- **Design Tokens:** Definir colores, espaciado, tipografía y radios como tokens CSS (`--color-primary`), nunca valores hardcodeados en componentes sueltos.
- **Responsive Mobile-First:** Escribir estilos base para móvil y escalar con `min-width` media queries (no al revés).
- **Reducir Reflows:** Animar solo propiedades que no causan layout thrash (`transform`, `opacity`).

## Rendimiento Frontend
- **Lazy Loading:** Cargar rutas y componentes pesados bajo demanda (React.lazy, dynamic import).
- **List Virtualization:** Para listas largas (>100 items), usar virtualización en lugar de renderizar todos los nodos DOM.
- **Memoización Selectiva:** Usar `useMemo`/`React.memo` solo donde el cálculo es costoso y provoca re-renders no deseados; evitar memoización indiscriminada.

## Anti-Patrones
- ❌ **Props drilling excesivo:** Pasar 5+ props por referencia a través de 3+ niveles de componentes. Usar contexto o estado global.
- ❌ **Estado derivable duplicado:** Almacenar `filteredList` en estado cuando es `useMemo(() => list.filter(...), [list])`.
- ❌ **JQuery-ismo en frameworks:** Mutar el DOM directamente o con `document.getElementById` en lugar de usar el binding del framework.
- ❌ **Componentes gigantes:** Archivos de 1000+ líneas. Dividir en sub-componentes con responsabilidad única. 
- ❌ **CSS global sin jerarquía:** Estilos con selectores globales que se pisan entre componentes (`.card`, `.button`). Usar CSS Modules, Tailwind o CSS-in-JS scoped.
- ❌ **Dependencia de una librería de UI para todo:** Reimplementar comportamientos nativos del navegador o el framework que agregan peso sin valor real.

## Integración con Otros Skills
- Se complementa con [`api-design`](../architecture/api-design.md) para definir el contrato de datos que los componentes consumen.
- Con [`ux-heuristics`](../analysis/ux-heuristics.md) para garantizar que la implementación respeta las heurísticas de usabilidad.
- Con [`test-strategy`](../qa/test-strategy.md) y [`testing-automation`](../qa/testing-automation.md) para definir la cobertura de pruebas de los componentes.