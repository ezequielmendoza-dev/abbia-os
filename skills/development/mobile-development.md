---
id: mobile-development
category: development
aliases: [mobile, react-native, mobile-apps]
type: method
version: 1.0
---

# Mobile Development

> Metodología para diseñar e implementar aplicaciones móviles (iOS/Android) mantenibles: arquitectura, plataforma, rendimiento y UX específica de móvil.

---

## Cuándo Usar Esta Skill
- Al diseñar una aplicación móvil o una funcionalidad nueva dentro de una app existente.
- Al definir la arquitectura de una app nativa o cross-platform.
- Al revisar la calidad e implementación de una app móvil.

## Principios Fundamentales
1. **Mobile-First (de verdad):** Pantallas pequeñas, interacción táctil, conexiones variables. El diseño ancestral para web no se traslada: se replanifica.
2. **Estado de Red Abrazado:** Las apps móviles viven con conectividad variable: pendientes, cache offline y sincronización son ciudadanos de primera clase, no excepciones.
3. **Rendimiento = Retención:** Cada frame drop o pantalla blanca cuesta usuarios. La app debe sentirse inmediata aunque los datos lleguen después.

## Arquitectura Recommended

- **Unidirectional Data Flow:** Estado global/del feature en stores (Redux, Zustand, Riverpod, MobX) con flujo de datos unidireccional. Evitar estado ensilado en mil componentes.
- **Capa de Repositorios:** Todo acceso a red o datos pasa por repositorios con interfaces; la UI no toca HTTP ni SQL directo. Habilita testing y mockeo.
- **URL-based navigation:** Para regresar al fondo/restaurar estado, la navegación declarativa (React Navigation, suFileNavigator, Jetpack Navigation) es preferible a pilas manuales.
- **Servicios de contención Flyweight:** Splash/boostrapping fuera del primer frame; feats detrás de una pantalla de carga controlada.

## Specificidades de Plataforma

### Cross-platform (React Native, Flutter, Kotlin Multiplatform)
- Respetar convenciones de cada SO (ej. Toolbar/AppBar, tabs, back behavior, gestures).
- Evitar la tentación de abstraer todo al mínimo común denominador.

### iOS
- SwiftUI/UIKit, Human Interface Guidelines (HIG): riesgo (destructive) con acción roja, Safe Area, Dynamic Type.
- Review de App Store incluye accesibilidad y permisos.

### Android
- Jetpack Compose/XML, Material Design 3, Gestión de back, scoped storage (permisos), Doze/battery constraints.

## Offline-First

- **Persistencia local:** SQLite/Realm/WatermelonDB para datos del dominio que se usan offline.
- **Cola de sincronización:** Mutaciones offline se encolan (idempotentes, versionadas) y se replaсan en reintento/reconexión.
- **Read-Trough Cache:** Leer del cache (inmediato) y refrescar de red en background (stale-while-revalidate).
- **Indicadores honestos:** Mostrar "datos guardados localmente / sin conexión" cuando corresponde; nunca mentir sobre el estado.

## Rendimiento Móvil

- **Listas virtualizadas/Optimización de ree-render:** FlatList/LazyList; evitar re-renders de toda la lista por un item.
- **Imágenes:** Loader progresivo + lazy content + WebP/AVIF + average ratio; nunca imágenes full-res en grid.
- **Memoria:** Cuidado con listeners no limpiados, suscripciones y referencias circulares en componentes desmontados.
- **Native modules puntualmente:** Para operaciones costosas (blur, modelado 3D), puente a código nativo.

## Anti-Patrones
- ❌ **Móvil como web encogida:** Puerto del layout web a una pantalla pequeña. El flujo debe replanificarse para tap, dedos y una mano.
- ❌ **Ignorar estados de red:** Mostrar pantallas vacías sin razón cuando falla la red, sin mensaje ni retry.
- ❌ **Permisos pedidos todos al inicio:** Pedir acceso a cámara/GPS en el primer prompt. Pedir en contexto, cuando se necesita.
- ❌ **Botones táctiles pequeños:** Targets de < 44x44pt. Frecuente causa de frustración y de reprocesos.
- ❌ **Mala gestión de estado:** Estado de pantalla en el componente con apuntes que se pierden al navegar (back pierde scroll o filtros).
- ❌ **Teclado que tapa inputs:** No manejar el keyboard avoidance. Patrón roto que se escapa en reviews.

## Integración con Otros Skills
- Consume [`ux-heuristics`](../analysis/ux-heuristics.md) para validar heurísticas de usabilidad móvil.
- Con [`backend-architecture`](../architecture/backend-architecture.md) para definir la API sincron/data que la app consume (offsets, pagination, sync).
- Con [`api-design`](../architecture/api-design.md) para contratos de API móvil-first (payloads livianos, offsets, `If-None-Match` para cache).
- Con [`testing-automation`](../qa/testing-automation.md) para E2E móvil (Detox, Maestro) y snapshot.

## Preguntas de Decisión de Plataforma

| Necesidad | Recomendación |
|:---|:---|
| Equipo pequeño, lanzar rápido en ambas plataformas | React Native/Flutter cross-platform |
| Rendimiento extremo (juegos, video, AR) | Nativo o nativo + motor especial |
| Equipos especializados por SO, integración nativa profunda | Nativo por plataforma |
| Compartir lógica de negocio entre web+móvil | KMP (lógica) + UI nativa, o RN/Flutter para skins compartidos |