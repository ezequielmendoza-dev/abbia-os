# Registro de Decisiones de Arquitectura y Técnicas (ADR / DEC)

## [ARCH-001] PostgreSQL como Base de Datos Principal
* **Fecha:** 2026-09-01
* **Estado:** APROBADO
* **Contexto:** Se requiere soporte para transacciones ACID y consistencia estricta en el procesamiento de órdenes.
* **Decisión:** Adoptar PostgreSQL 16 gestionado con Prisma ORM.
* **Consecuencias:** Integridad relacional garantizada; requiere migraciones declarativas y pool de conexiones controlado.

## [ARCH-002] Autenticación Basada en JWT y Refresh Tokens
* **Fecha:** 2026-09-05
* **Estado:** APROBADO
* **Contexto:** Se necesita autenticación segura stateless para la API móvil y web.
* **Decisión:** Emitir Access Token (15 min) y Refresh Token (7 días) en cookie `HttpOnly`.
* **Consecuencias:** Mitiga riesgos de XSS; requiere rotación de refresh tokens en base de datos.
