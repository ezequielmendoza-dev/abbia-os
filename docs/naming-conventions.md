# Convenciones de Nomenclatura — ai-agents

> **Versión:** 1.0  
> **Estado:** Vigente  
> **Última actualización:** Junio 2026

---

## Principio General

Los identificadores en este sistema son:
- **Únicos** — nunca se reutiliza un ID, aunque la feature sea cancelada
- **Secuenciales** — se asignan en orden, sin saltos intencionales
- **Descriptivos** — el slug después del número describe el contenido
- **Estables** — una vez asignado, un ID no cambia

---

## Identificadores de Feature

### Formato

```
FEAT-NNN-slug-descriptivo
```

| Componente | Descripción | Ejemplo |
|-----------|-------------|---------|
| `FEAT` | Prefijo fijo para features | `FEAT` |
| `NNN` | Número secuencial de 3 dígitos con ceros a la izquierda | `001`, `042`, `123` |
| `slug-descriptivo` | Descripción corta en kebab-case, en inglés o español | `seat-layout`, `aprobacion-asientos` |

### Ejemplos válidos

```
FEAT-001-seat-layout
FEAT-002-seat-approval
FEAT-003-discount-engine
FEAT-042-user-notifications
FEAT-100-reporting-dashboard
```

### Ejemplos inválidos

```
FEAT-1-seat-layout        ❌  (número sin padding)
feat-001-seat-layout      ❌  (prefijo en minúsculas)
FEAT-001_seat_layout      ❌  (guiones bajos en lugar de guiones)
FEAT-001                  ❌  (sin slug descriptivo)
FEATURE-001-seat-layout   ❌  (prefijo incorrecto)
```

### Dónde se usa

- Nombre de la carpeta: `.ai/features/FEAT-001-seat-layout/`
- En los documentos internos: campo `Feature ID: FEAT-001`
- En nombres de branches de Git: `feat/001-seat-layout`
- En commits: `feat(FEAT-001): add seat layout model`

---

## Identificadores de Bug

### Formato

```
BUG-NNN-slug-descriptivo
```

| Componente | Descripción | Ejemplo |
|-----------|-------------|---------|
| `BUG` | Prefijo fijo para bugs | `BUG` |
| `NNN` | Número secuencial de 3 dígitos | `001`, `023` |
| `slug-descriptivo` | Descripción corta del problema | `double-booking`, `auth-timeout` |

### Ejemplos válidos

```
BUG-001-double-booking
BUG-002-auth-token-expiry
BUG-023-seat-count-mismatch
```

### Dónde se usa

- En el reporte de QA: `BUG-001` como ID interno
- En nombres de branches: `fix/001-double-booking`
- En commits: `fix(BUG-001): prevent double booking on concurrent requests`
- En el workflow de bug-fix: referencia al BUG-XXX

---

## Identificadores de Iniciativas Especiales (AUDIT y REF)

Además de `FEAT` y `BUG`, el sistema soporta dos tipos de iniciativa con **estructura libre** (sin documentos obligatorios por convención; cada una define los suyos):

| Prefijo | Tipo | Ejemplo | Uso típico |
|-----------|-----|---------|------------|
| `AUDIT` | Auditoría / Seguridad | `AUDIT-001-ecosystem-audit` | Auditorías de seguridad, revisión de arquitectura, compliance |
| `REF` | Refactor | `REF-001-migrate-payments-service` | Refactors técnicos, migraciones, deuda técnica |

### Formato

```
AUDIT-NNN-slug-descriptivo
REF-NNN-slug-descriptivo
```

### Reglas

- Mismo `NNN` (3 dígitos con padding) y slug kebab-case que FEAT/BUG
- **Estructura libre:** el validador no exige archivos concretos; solo verifica que la carpeta no esté vacía
- Se registran en `.ai/context.md` (`Último AUDIT asignado`, `Último REF asignado`)
- En commits: `audit(AUDIT-001): ...` / `refactor(REF-001): ...`

---

## Identificadores de Decisión de Arquitectura

### Formato

```
ARCH-NNN
```

| Componente | Descripción | Ejemplo |
|-----------|-------------|---------|
| `ARCH` | Prefijo fijo para Architecture Decision Records | `ARCH` |
| `NNN` | Número secuencial de 3 dígitos | `001`, `012` |

> **Nota:** Los ADR no tienen slug porque su título descriptivo vive dentro del documento.

### Ejemplos válidos

```
ARCH-001
ARCH-012
ARCH-045
```

### Dónde se usa

- En `.ai/decisions.md`: cada entrada tiene un `ARCH-XXX`
- En `decision.md` dentro de una feature cuando la feature genera una decisión de arquitectura global
- Referenciado en `architecture.md` cuando se implementa: `Ver ARCH-012`

---

## Nomenclatura de Documentos

### Documentos permanentes (`.ai/`)

Estos nombres son **fijos y no negociables**. No se puede cambiar su nombre ni agregar variantes:

| Archivo | Propósito | ¿Se puede renombrar? |
|---------|-----------|---------------------|
| `context.md` | Identidad del proyecto | No |
| `business-rules.md` | Reglas de negocio permanentes | No |
| `architecture.md` | Arquitectura actual del sistema | No |
| `decisions.md` | Log de decisiones (append-only) | No |
| `glossary.md` | Glosario del dominio | No |

### Documentos de feature (`.ai/features/FEAT-XXX/`)

Estos nombres son **fijos dentro de cada feature**:

| Archivo | Propósito | ¿Se puede renombrar? |
|---------|-----------|---------------------|
| `spec.md` | Especificación funcional de la feature | No |
| `architecture.md` | Diseño técnico de la feature | No |
| `qa.md` | Reporte de QA de la feature | No |
| `decision.md` | Decisiones específicas de la feature | No |

---

## Nomenclatura de Branches de Git

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Feature | `feat/NNN-slug` | `feat/001-seat-layout` |
| Bug fix | `fix/NNN-slug` | `fix/023-double-booking` |
| Refactor | `refactor/slug` | `refactor/auth-module` |
| Hotfix | `hotfix/slug` | `hotfix/payment-crash` |
| Release | `release/vX.Y.Z` | `release/v2.1.0` |

---

## Nomenclatura de Commits

Seguir el estándar [Conventional Commits](https://www.conventionalcommits.org/):

```
tipo(scope): descripción en presente

[cuerpo opcional]
[footer opcional]
```

| Tipo | Cuándo usar |
|------|------------|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `refactor` | Refactorización sin cambio de comportamiento |
| `docs` | Solo cambios en documentación |
| `test` | Agregar o corregir tests |
| `chore` | Cambios de infraestructura, dependencias, CI/CD |

### Ejemplos

```
feat(FEAT-001): add seat layout data model
fix(BUG-023): prevent seat count from going negative
docs: update architecture.md with new auth flow
refactor(auth): extract token validation to separate service
```

---

## Registro de IDs

> [!IMPORTANT]
> Cada proyecto debe mantener un registro de IDs asignados en `.ai/context.md` para evitar colisiones. Ejemplo:
> ```markdown
> ## Registro de IDs
> - Último FEAT asignado: FEAT-012
> - Último BUG asignado: BUG-034  
> - Último ARCH asignado: ARCH-007
> ```

---

*Convenciones de nomenclatura v1.0 — ai-agents library | github.com/ezequielmendoza-dev/ai-agents*
