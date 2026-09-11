---
id: database-design
category: architecture
aliases: [data-modeling, database, data-architecture]
type: method
version: 1.0
---

# Database Design

> Metodología para modelar datos de forma clara, escalable y evolucionable: entidades, relaciones, índices, migraciones y consistencia.

---

## Cuándo Usar Esta Skill
- Al diseñar el modelo de datos de una nueva funcionalidad o sistema.
- Al revisar el esquema de una base de datos existente con deuda técnica.
- Al decidir entre SQL/NoSQL, normalización y estrategias de migración.

## Principios Fundamentales
1. **Modelar el Dominio, no la UI:** Las entidades deben reflejar el dominio de negocio, no la forma de una pantalla o endpoint.
2. **Nombre las Cosas Bien:** Tablas en plural (`users`), columnas descriptivas (`created_at`), claves foráneas explícitas (`user_id`). La coherencia de nombres vale más que cualquier optimización posterior.
3. **Migraciones como Historia:** Toda evolución del esquema es una migración versionada, reversible y con nombres descriptivos.

## Modelado de Entidades

- **Identificadores:** Preferir IDs generados por la aplicación (UUIDv7) o autonuméricos según convención; evitar claves naturales frágiles (email, DNI) como PK cuando pueden cambiar.
- **Timestamps:** Incluir `created_at` y `updated_at` en toda tabla core; `deleted_at` si se usa soft delete.
- **Estandarización de tipos:** Fijar convenciones (ej. dinero como `DECIMAL(18,2)` o enteros en centavos, fechas como `TIMESTAMPTZ`).
- **Enums:** Valores con cardinalidad fija y pequeña van en CHECK constraints o tablas de referencia; no en strings libres.

## Relaciones

| Relación | Estrategia |
|:---|:---|
| 1:N | Foreign key en el lado "many" |
| N:M | Tabla pivote con índices compuestos en ambas columnas |
| 1:1 | FK única en la tabla secundaria, o tabla única si se acceden siempre juntas |
| Jerárquicas | `parent_id` recursivo, o materialized path según profundidad/características de consulta |

- **Restricciones de Integridad:** Usar `ON DELETE CASCADE` con cuidado; para datos valiosos preferir `RESTRICT` + borrado lógico.

## Índices

- **Índice por Convención en FK:** Toda columna FK usada en joins debe estar indexada.
- **Índices Compuestos:** Ordenar columnas por cardinalidad de consulta (las más selectivas primero).
- **Sobrecarga de índices:** Cada índice extra cuesta escritura y almacenamiento. Índice = pagas con writes, cobras con reads. Solo indexar lo que las queries realmente usan.

## Migraciones

- **Naming:** `001_create_users.sql`, `002_add_user_last_login.sql` — incremental y descriptivo.
- **Retrocompatibilidad:** Las migraciones deben poder desplegarse sin romper la versión anterior del código (agregar columna nullable antes de removerla, etc).
- **Expansión-Contracción:** Para cambios destructivos: (1) agregar nuevo campo/tabla, (2) backfill y doble escritura, (3) switch de lectura, (4) remover lo viejo (data migration).
- **Rollback:** Cada migración debe tener estrategia de reversión o al menos ser reversible.

## Consistencia y Concurrencia

- **Transacciones ACID:** Aislamiento coherente para operaciones multi-tabla en sistemas relacionales.
- **Optimistic vs. Pessimistic Locking:** Optimistic (version column) para lecturas concurrentes con baja contención; pessimistic (`SELECT FOR UPDATE`) para operaciones de alta contención que no toleran reintentos.
- **Soft Delete vs. Hard Delete:** Soft delete conserva trazabilidad y referencias; hard delete ahorra espacio. Definir política por modelo.

## Anti-Patrones
- ❌ **Anti-pattern del "kitchen sink":** Tablas en las que se van agregando columnas sueltas sin cohesión. Agregar todas las columnas de cada screen.
- ❌ **EAV innecesario:** `(entity_id, attribute, value)` para modelar atributos dinámicos donde una tabla real con columnas nullable es más simple y consultable.
- ❌ **Sin restricciones FK:** Forzar integridad solo en la aplicación; la BD debe ser la fuente de verdad.
- ❌ **Migraciones destructivas inmediatas:** Dropear columnas o tablas en la misma migración que las reemplaza, rompiendo la versión anterior en producción.
- ❌ **Consultas N+1:** Traer listas y luego consultar por registro (ORMs). Usar JOINs, eager loading o batching.
- ❌ **Guardar todo como JSON:** Una columna JSON es pragmática para documentos, pero si consultas campos internos o paginas por ellos, debe ser una tabla.

## Integración con Otros Skills
- Se complementa con [`backend-architecture`](backend-architecture.md) para capa de persistencia y repositorios.
- Con [`api-design`](api-design.md) para alinear el contrato de recursos con el modelo.
- Con [`performance-tuning`](performance-tuning.md) para optimización de queries.

## Cuándo Seleccionar SQL vs NoSQL
- **Relacional (PostgreSQL, MySQL):** Relaciones, transacciones, integridad, reporting ad-hoc. Elección por defecto.
- **Documentos (MongoDB, DynamoDB):** Lecturas por documento completo, esquema flexible, escalado horizontal con workload de lectura/escritura de un access pattern conocido.
- **Grafos:** Relaciones del tipo "qué se conecta a qué" (recomendaciones, permisos, redes).
- **Time-series:** Métricas, logs, eventos con alta cardinalidad temporal.
- Regla: **empezar relacional** salvo que el caso de uso empuje claramente hacia un modelo de acceso distinto.