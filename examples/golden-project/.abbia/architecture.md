# Arquitectura del Sistema

## 1. Diagrama de Alto Nivel
```
[Next.js Client] ──(HTTPS/REST)──► [Fastify API Gateway] ──► [Domain Services] ──► [PostgreSQL]
```

## 2. Patrones Arquitectónicos
- **Patrón Principal:** Modular Monolith con Clean Architecture (Domain -> Application -> Infrastructure).
- **Manejo de Errores:** Errores canónicos (`AppError`) con códigos de estado HTTP tipados.
- **Autenticación:** JWT con Refresh Tokens en cookies `HttpOnly` y `Secure`.

## 3. Convenciones de Código
- **Lenguaje:** TypeScript (strict mode activado).
- **Naming:** `camelCase` para variables/funciones, `PascalCase` para componentes/clases, `kebab-case` para archivos y rutas.
- **Testing:** Cobertura mínima del 80% en lógica de dominio con Vitest.
