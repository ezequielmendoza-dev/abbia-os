---
id: ux-heuristics
category: analysis
aliases: [ux, usability, heuristics-evaluation]
type: method
version: 1.0
---

# UX Heuristics

> Metodología para evaluar y diseñar la experiencia de usuario aplicando heurísticas de usabilidad, accesibilidad y persuasión basadas en evidencia.

---

## Cuándo Usar Esta Skill
- Durante la especificación funcional, para validar que el diseño de flujos es usable a nivel conceptual.
- Al revisar un diseño de UI propuesto por el UI Designer.
- Al auditar un flujo existente con problemas de conversión o abandono.

## Principios Fundamentales
1. **El Usuario no Lee, Escanea:** La información debe ser escaneable: jerarquía visual, títulos descriptivos, espacios en blanco.
2. **Menos es Más:** Reducir carga cognitiva. Cada elemento extra compite por la atención del usuario.
3. **Consistencia Interna:** Lo que funciona igual debe verse igual; si se ve distinto, debe comportarse distinto.

## Heurísticas de Evaluación (basadas en Nielsen)

| Heurística | Pregunta de Evaluación |
|:---|:---|
| Visibilidad del estado del sistema | ¿Sabe el usuario qué está pasando? ¿Hay feedback en < 1s? |
| Match con el mundo real | ¿Usa el lenguaje del usuario, no el del sistema? |
| Control y libertad del usuario | ¿Puede deshacer? ¿Hay "salida de emergencia"? |
| Consistencia y estándares | ¿Sigue convenciones de plataforma? |
| Prevención de errores | ¿Previene errores antes de que ocurran, no solo los explica? |
| Reconocer en vez de recordar | ¿Están visibles las opciones, o el usuario debe memorizarlas? |
| Flexibilidad y eficiencia | ¿Hay atajos/accelerators para usuarios avanzados? |
| Diseño minimalista | ¿Hay información irrelevante o raramente necesaria? |
| Recuperación de errores | ¿Los mensajes de error dicen qué pasó y cómo arreglarlo? |
| Ayuda y documentación | ¿Hay ayuda disponible sin sobrecargar? |

## Flujos y Microdecisiones de UX

- **Onboarding:** Primera impresión en < 3 pasos; demostrar valor antes de pedir registro.
- **Empty States:** El primer estado vacío debe indicar qué hacer, no un lienzo en blanco.
- **Estados de Formularios:** Validar en el blur y en submit, nunca solo en submit. Para errores, mensaje junto al campo y resumen arriba.
- **Confirmaciones Destructivas:** Alertas nativas para acciones que no tienen retorno (borrar, enviar, pagar).

## Accesibilidad (W3C WCAG 2.1 AA)

- **Contraste:** Texto normal ≥ 4.5:1; texto grande o componentes UI ≥ 3:1.
- **Navegación por teclado:** Todo el flujo operable con Tab/Enter/Space; foco visible en cada parada.
- **ARIA:** Usar roles/labels solo cuando los elementos nativos no bastan; no sobrecargar con ARIA redundante.
- **Soporte de lectores de pantalla:** Textos descriptivos en links, alt en imágenes significativas, `aria-label` en iconos sin texto.
- **Motion:** Respetar `prefers-reduced-motion`; no obligar animaciones barrocas.

## Test de Usabilidad Liviano (sin laboratorio)
1. **Test de los 5 segundos:** Mostrar una pantalla 5s, luego preguntar de qué trata. Mide la claridad de la comunicación primaria.
2. **Test de escaneo:** Preguntar al usuario dónde haría clic para X. Mide discoverability.
3. **Test de primera tarea:** Dar una tarea crítica y observar sin intervenir. Mide fricción real.

## Persuasión y Conversión (evidencia aplicada)
- **Defaults poderosos:** Pre-seleccionar la opción recomendada para la mayoría.
- **Prueba social:** Mostrar "qué hacen otros" cuando reduce incertidumbre.
- **Urgencia honesta:** Sellos de scarcity reales; nunca falsos.
- **Pérdida de aversión:** "Tu carrito te espera" funciona mejor que "Vuelve" para reenganche.

## Anti-Patrones
- ❌ **Efecto "túnel":** Forzar al usuario a un solo camino sin alternativas o salida clara.
- ❌ **Patrones engañosos (dark patterns):** Confirmar omitiendo la opción de no suscribirse, otogonal, teletransporte. Dañan la confianza a largo plazo.
- ❌ **Exceso de opciones:** Parálisis de decisión cuando hay demasiados caminos idénticos (iconos no etiquetados).
- ❌ **Feedback genérico:** "Error" sin decir qué pasó ni cómo arreglarlo. El usuario asume que él hizo algo mal.
- ❌ **Diseño obviamente responsive-less:** Ignorar que el 60%+ del tráfico es móvil.

## Integración con Otros Skills
- Alimenta al [UI Designer](../../roles/ui-designer.md) con criterios de evaluación del diseño.
- Se cruza con [`frontend-patterns`](../development/frontend-patterns.md) para implementar la accesibilidad en código.
- Con [`requirements-discovery`](requirements-discovery.md) para validar que los flujos definidos son usables desde el descubrimiento.