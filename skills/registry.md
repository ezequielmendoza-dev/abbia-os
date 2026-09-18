# Skill Registry Rules

> **Versión:** 2.0  
> **Propósito:** Define las reglas maestras de cómo `ai-agents` cataloga, clasifica y resuelve conflictos de skills descubiertas dinámicamente.  
> **Nota:** Este archivo **NO** es una lista estática de tecnologías.

---

## 1. Skill Sources (Fuentes de Origen)

Cada skill que el Skill Manager procesa debe estar etiquetada con su origen. La fuente determina su nivel de autoridad en el sistema.

| Nivel | Fuente (Source) | Descripción | Autoridad |
|-------|-----------------|-------------|-----------|
| L1 | `Project` | Skills alojadas en el repositorio actual (ej. `.skills/`). Representan la voluntad explícita del proyecto. | Máxima (100) |
| L2 | `UserExternal` | Skills instaladas por el usuario en su entorno (ej. Gemini Plugins, Claude Code). | Alta (80) |
| L3 | `Framework` | Skills metodológicas internas de `ai-agents` (`skills/analysis/`, etc). | Media (50) |
| L4 | `LLM` | Conocimiento base pre-entrenado. | Baja (0) |

## 1.1 Adquisición de Skills (Catálogo skills.sh)

Para subsanar las brechas tecnológicas identificadas (tecnologías detectadas en manifiestos pero sin skill activa), el Skill Manager sugerirá la instalación de la skill desde el catálogo público de referencia: [skills.sh](https://www.skills.sh/).
- Las skills instaladas a través de este catálogo se incorporan al proyecto o entorno como `L1 (Project)` o `L2 (UserExternal)`.
- La sugerencia detalla la URL exacta (ej: `https://www.skills.sh/skills/<id-skill>`), el agente a potenciar y su justificación.

## 2. Skill Types (Tipos de Skills)

Para facilitar la orquestación, las skills se clasifican por su propósito, independientemente de su fuente:

- **Methodological (`type: method`):** Definen *cómo* ejecutar un proceso de ingeniería (ej. `api-design`, `code-review`). Las `Framework Skills` siempre son de este tipo.
- **Technological (`type: tech`):** Definen *cómo* utilizar una herramienta específica (ej. `react`, `docker`). Vienen de `Project` o `UserExternal`.
- **Business (`type: business`):** Definen reglas de negocio, glosarios o dominio específico del producto. Generalmente vienen de `Project`.

## 3. Skill Prioritization (Priorización y Shadowing)

Cuando el orquestador encuentra múltiples skills con el mismo **ID** o **Alias**:
1. Se ordena la lista de skills candidatas por Autoridad (ver tabla en sección 1).
2. La skill con mayor autoridad gana (Shadowing) y se carga en el contexto.
3. Las skills perdedoras se descartan y se registran en el *Skill Activation Report* bajo "Skills Descartadas por Shadowing".

## 4. Conflict Resolution (Resolución de Conflictos)

Los conflictos ocurren cuando se detectan skills con **IDs diferentes** pero que son lógicamente incompatibles (ej. detectar skills de `express` y `nestjs` simultáneamente para un microservicio monolítico).

### Reglas de Manejo de Conflictos:
1. **Revisión de Contexto Duro:** El Skill Manager debe examinar los manifiestos del proyecto (`package.json`, `Cargo.toml`, etc.) o el `.abbia/context.md`. La skill que esté respaldada por el manifiesto se mantiene; las demás se descartan.
2. **Intervención Humana Exigida:** Si los manifiestos no resuelven la ambigüedad, el Skill Manager **debe detener la ejecución** (usando herramientas como `ask_question`) para que el desarrollador humano decida. Nunca debe avanzar con un contexto tecnológico esquizofrénico o mezclado.

## 2.1 Categorías Framework (skills `type: method`)

El framework agrupa sus skills metodológicas en 5 categorías de dominio. Cada categoría alimenta a un grupo de roles:

| Categoría | Rol(es) que consume(n) | Skills framework |
|:---|:---|:---|
| `analysis` | Product Analyst, UI Designer | `requirements-discovery`, `ux-heuristics` |
| `architecture` | Software Architect, Developer, Tech Lead | `api-design`, `backend-architecture`, `database-design`, `performance-tuning`, `ai-integration` |
| `development` | Senior Developer, QA | `code-review`, `frontend-patterns`, `mobile-development` |
| `qa` | QA Engineer, Tech Lead | `test-strategy`, `testing-automation`, `security-audit` |
| `workflow` | DevOps Engineer, Tech Lead | `release-readiness`, `devops-pipeline` |

> Las categorías por tecnología del README histórico (`frontend/`, `backend/`, etc.) corresponden a skills `type: tech` que **no se shippean en el framework**; se descubren dinámicamente desde `Project` (L1) o `UserExternal` (L2).

## 5. El Catálogo Dinámico

El Skill Manager no mantiene un JSON o tabla estática. Al iniciar una sesión de trabajo:
1. Recolecta.
2. Aplica Shadowing.
3. Resuelve Dependencias transitivas.
4. Aplica Resolución de Conflictos.
5. Genera el **Skill Activation Report** que consumirán los agentes subsecuentes (Developer, Architect, etc).
