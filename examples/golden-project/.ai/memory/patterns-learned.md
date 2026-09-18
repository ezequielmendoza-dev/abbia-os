# Patrones Aprendidos — Memoria Procedimental

## Aislamiento de Transacciones en Pruebas con PostgreSQL

- **Síntoma:** Tests paralelos fallaban por colisión de claves únicas de usuario.
- **Causa raíz:** Múltiples tests compartían la misma base de datos sin truncar tablas entre ejecuciones.
- **Solución aplicada:** Usar transacciones rollback automáticas por cada test suite en Vitest.
- **Aplica a:** Todos los tests de integración en backend Fastify.
