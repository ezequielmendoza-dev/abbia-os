---
id: backend-architecture
category: architecture
aliases: [backend, server-side, backend-design]
type: method
version: 1.0
---

# Backend Architecture

> Metodología para diseñar servicios backend robustos, desacoplados y evolucionables: capas, modularidad, manejo de errores y contratos de datos.

---

## Cuándo Usar Esta Skill
- Al diseñar la arquitectura de un nuevo servicio o microservicio.
- Al estructurar un backend existente que mezcla responsabilidades.
- Al definir el manejo de errores, validaciones y contratos de datos entre servicios.

## Principios Fundamentales
1. **Arquitectura en Capas:** Separar claramente transporte (controllers/routes), aplicación (servicios/usecases), dominio (lógica de negocio pura) e infraestructura (repositorios, clientes externos).
2. **Inversión de Dependencias:** El dominio no debe conocer la infraestructura. Interfaces en el dominio, implementaciones en la infraestructura.
3. **Contratos Explícitos:** Toda entrada y salida de un servicio se declara con tipos/validación (schemas), nunca objetos implícitos.

## Estructura de Capas

```
├── transport/     # Controllers, routes, middleware (HTTP/gRPC/GraphQL)
├── application/   # Use cases, DTOs, orquestación de flujos, transacciones
├── domain/        # Entidades, value objects, reglas de negocio puras (sin deps)
└── infrastructure/ # Repos, clientes HTTP, cache, message brokers, cron jobs
```

- El **transporte** solo valida formato de entrada y serializa la respuesta.
- La **aplicación** orquesta casos de uso y gestiona transacciones/eventos.
- El **dominio** implementa reglas de negocio inmutables y sin dependencias externas.

## Manejo de Errores

- **Errores Esperados vs. Inesperados:** Distinguir errores de negocio (validación, conflicto de estado) de errores de infraestructura (BD caída, timeout). Mapear los primeros a códigos HTTP 4xx y los segundos a 5xx.
- **Errores Estructurados:** Devolver un esquema estándar de error: `{ code, message, details?, requestId }`.
- **No exponer stack traces:** En producción, el `requestId` permite correlacionar logs sin filtrar información interna.
- **Retry con Backoff:** Para llamadas a infraestructura idempotentes (BD, colas), implementar retries con backoff exponencial y jitter.

## Comunicación entre Servicios

- **Síncrona (HTTP/gRPC):** Para consultas y comandos con respuesta inmediata. Definir timeouts y circuit breakers.
- **Asíncrona (Message Broker/Event Bus):** Para integraciones desacopladas y eventos de dominio. Los productores emiten eventos; los consumidores reaccionan.
- **Idempotencia:** Todo handler que recibe mensajes repetidos debe producir el mismo resultado (dedup keys, versionado en mensajes).

## Seguridad en Backend

- **Validación de Entrada:** Validar schemas en el límite del servicio (DTOs con Zod/Pydantic/Joi) antes de tocar el dominio.
- **Autenticación y Autorización:** AuthN en el transporte (JWT/OAuth2), AuthZ en la aplicación (roles/permisos por recurso).
- **Rate Limiting:** Proteger los endpoints públicos y los de autenticación contra abuso.
- **Secretos:** Nunca almacenar claves en el código; usar secret managers o variables de entorno.

## Anti-Patrones
- ❌ **Controller gordo:** Rutas con lógica de negocio, queries y formateo mezclados. El controller debe quedar delgado.
- ❌ **God Service:** Servicios con cientos de métodos que tocan todos los dominios. Dividir por agregados o bounded contexts.
- ❌ **Anemic Domain:** Entidades que son solo DTOs con getters, y toda la lógica fuera. La lógica de negocio vive en el dominio.
- ❌ **Manejo de errores genérico:** Catch-all que devuelve `500` o `error` sin contexto para todo.
- ❌ **Dependencia circular:** App y dominio importando infraestructura. Respeta la dirección de las capas.

## Integración con Otros Skills
- Define el contrato consumido por [`api-design`](api-design.md) para las APIs expuestas.
- Se coordina con [`database-design`](database-design.md) para el modelo de persistencia.
- Con [`security-audit`](../qa/security-audit.md) para validar la postura de seguridad del diseño.
- Con [`test-strategy`](../qa/test-strategy.md) para planificar la cobertura por capa.