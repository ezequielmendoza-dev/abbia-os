# Integración de ai-agents en Proyectos

> **Audiencia:** Desarrolladores que quieren usar esta biblioteca en sus proyectos  
> **Prerequisito:** Tener acceso a [github.com/ezequielmendoza-dev/ai-agents](https://github.com/ezequielmendoza-dev/ai-agents)

---

## Tabla de Contenidos

1. [Filosofía de integración](#1-filosofía-de-integración)
2. [Estructura .ai/ en cada proyecto](#2-estructura-ai-en-cada-proyecto)
3. [Integración con Git Submodules](#3-integración-con-git-submodules)
4. [Mantener los agentes sincronizados](#4-mantener-los-agentes-sincronizados)
5. [Configurar el contexto del proyecto](#5-configurar-el-contexto-del-proyecto)
6. [Integración con IDEs](#6-integración-con-ides)
7. [Compartir contexto entre proyectos](#7-compartir-contexto-entre-proyectos)
8. [Ejemplos por tipo de proyecto](#8-ejemplos-por-tipo-de-proyecto)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Filosofía de Integración

El principio fundamental es **referenciar, nunca copiar**.

```
❌ MAL: Copiar los archivos de ai-agents dentro del proyecto
✅ BIEN: Referenciar ai-agents desde el proyecto vía Git Submodule
```

**Por qué submodule y no copia:**

| | Copia | Submodule |
|--|-------|-----------|
| Actualizaciones de agentes | Manual en cada proyecto | `git submodule update` |
| Sincronización | Imposible a escala | Automática |
| Fuente de verdad | Múltiple (deriva) | Única |
| Tamaño del repo | Crece | Solo una referencia |

---

## 2. Estructura `.ai/` en cada Proyecto

Cada proyecto que usa `ai-agents` debe tener una carpeta `.ai/` en su raíz:

```
mi-proyecto/
├── src/
├── .ai/
│   ├── agents/          ← Git Submodule apuntando a ai-agents
│   ├── context.md       ← Contexto del proyecto (basado en templates/project-context.md)
│   └── sessions/        ← Sesiones de trabajo (ignorado por git del proyecto)
├── .gitignore
└── README.md
```

### ¿Qué va en `.ai/`?

| Archivo/Carpeta | Origen | Descripción |
|----------------|--------|-------------|
| `agents/` | Git Submodule de `ai-agents` | Todos los agentes, templates, checklists y workflows |
| `context.md` | Completado manualmente | Memoria del proyecto — se actualiza con el tiempo |
| `sessions/` | Generado localmente | Conversaciones o notas de sesiones de trabajo (no se commitea) |

### Agregar `.ai/sessions/` al `.gitignore` del proyecto

```gitignore
# AI sessions — trabajo local, no compartir en el repo del proyecto
.ai/sessions/
```

---

## 3. Integración con Git Submodules

### 3.1 Agregar ai-agents a un proyecto nuevo

```bash
# Desde la raíz del proyecto
mkdir -p .ai
git submodule add https://github.com/ezequielmendoza-dev/ai-agents.git .ai/agents
git commit -m "chore: add ai-agents as submodule in .ai/agents"
```

Esto crea:
- La carpeta `.ai/agents/` con todo el contenido de `ai-agents`
- El archivo `.gitmodules` en la raíz del proyecto

```ini
# .gitmodules (generado automáticamente)
[submodule ".ai/agents"]
    path = .ai/agents
    url = https://github.com/ezequielmendoza-dev/ai-agents.git
```

---

### 3.2 Clonar un proyecto que ya tiene el submodule

```bash
# Opción A: clonar incluyendo submodules en un solo comando
git clone --recurse-submodules https://github.com/tu-org/mi-proyecto.git

# Opción B: clonar primero, inicializar submodule después
git clone https://github.com/tu-org/mi-proyecto.git
cd mi-proyecto
git submodule update --init --recursive
```

---

### 3.3 Verificar el estado del submodule

```bash
# Ver estado del submodule (commit al que apunta)
git submodule status

# Ejemplo de output:
# acb08b8 .ai/agents (v2.0.1)
```

---

## 4. Mantener los Agentes Sincronizados

### 4.1 Actualizar al último commit de ai-agents

```bash
# Desde la raíz del proyecto — en un solo comando:
# actualiza el submodule, commitea el puntero y ejecuta setup-ide.sh --auto
bash .ai/agents/scripts/update-ai-agents.sh
```

Equivale a hacer manualmente `git submodule update --remote .ai/agents`, revisar el log (`cd .ai/agents && git log --oneline -5`) y commitear el puntero.

### 4.2 Actualizar a una versión específica (tag)

```bash
# Pin a un tag concreto (submodule + setup en un comando)
bash .ai/agents/scripts/update-ai-agents.sh v3.2.2
# Si prefieres control total de los pasos, puedes hacerlo manualmente:
cd .ai/agents
git checkout v3.2.2       # apuntar a un tag específico
cd ../..
git add .ai/agents
git commit -m "chore: pin ai-agents to v3.2.2"
```

### 4.3 Estrategia recomendada por tipo de proyecto

| Proyecto | Estrategia | Razón |
|----------|------------|-------|
| En desarrollo activo | Usar `main` branch, actualizar frecuentemente | Beneficiarse de mejoras |
| En producción estable | Pinear a un tag | Estabilidad ante cambios inesperados |
| Proyecto crítico | Pinear + revisar CHANGELOG antes de actualizar | Control total |

### 4.4 Actualizar desde v3.0 a v3.2.x — Qué cambia y qué hacer

Este apartado aplica a proyectos que ya usaban `ai-agents` v3.0.x y quieren aprovechar los sistemas nuevos (v3.1.0 → v3.2.x).

#### Qué se actualiza automáticamente (vía submodule)

Al actualizar el submodule, todo esto se aplica **sin intervención manual**:

| Componente | Cambio |
|:---|:---|
| 8 agentes (roles/*.md) | Alineados a **v3.0** (incl. skill-manager v1.2 → v3.0) |
| 15 framework skills (skills/) | 5 existentes + 10 nuevas metodológicas |
| 5 workflows (workflows/*.md) | Contienen DAG embebido (bloque `<!-- dag:start -->`/`<!-- dag:end -->`) |
| Skill Manager | Nuevo rol orquestador de memoria, DAG y skills |
| scripts/ | `setup-ide.sh` v1.8.0, `update-ai-agents.sh` y `validate-project.sh` actualizados |

#### Qué requiere activación manual

Los sistemas nuevos de v3.2.0 **no se crean solos** al actualizar el submodule. La forma más simple es usar el actualizador de un solo comando:

**Opción A — Actualizador de un comando (recomendado):**
```bash
bash .ai/agents/scripts/update-ai-agents.sh        # último commit
bash .ai/agents/scripts/update-ai-agents.sh v3.2.2 # pin a un tag
```
Este comando actualiza el submodule, commitea el puntero y ejecuta `setup-ide.sh --auto`. Los sistemas nuevos se activan sin preguntas (idempotente):
- Se crea `.ai/memory/` con sus 4 archivos seed
- Se crea `.ai/metrics/executions.yaml` (seed de métricas)
- Se crea `.ai/knowledge-graph.yaml` (grafo vacío para indexar decisiones)
- No se regeneran las reglas IDE (evita sobrescribir copias del proyecto)

**Opción B — Rerun del setup manual (para regenerar reglas IDE):**
```bash
bash .ai/agents/scripts/setup-ide.sh
```
Este comando es idempotente: solo crea archivos que no existen, y además regenera los archivos de reglas IDE (`.cursorrules`, `CLAUDE.md`, etc.) con las nuevas referencias.

**Opción C — Creación manual:**
```bash
mkdir -p .ai/memory .ai/metrics
# Copiar seeds desde los templates del submodule
cp .ai/agents/templates/metrics-executions.yaml .ai/metrics/executions.yaml
cp .ai/agents/templates/knowledge-graph.yaml .ai/knowledge-graph.yaml
# Memoria: ver contratos en .ai/agents/docs/workflow-memory.md
```

#### Qué NO es retroactivo (no se puede recuperar)

| Sistema | Situación | Consecuencia |
|:---|:---|:---|
| **Memoria persistente** (`.ai/memory/`) | Arranca vacía al crearse | Las sesiones anteriores al upgrade no aparecen en el log |
| **Métricas** (`.ai/metrics/`) | Arranca vacía al crearse | No se miden ejecuciones pasadas |
| **Knowledge Graph** (`.ai/knowledge-graph.yaml`) | Arranca vacío | Los ADRs existentes en `decisions.md` no se indexan automáticamente |

**Backfill manual de ADRs en el Knowledge Graph** (recomendado para proyectos con historial):
```bash
# Abrir .ai/knowledge-graph.yaml y agregar un nodo por cada ARCH-NNN vigente en decisions.md
# Formato del nodo (ver templates/knowledge-graph.yaml):
nodes:
  - id: ARCH-001
    title: "Nombre corto"
    status: ACTIVE
    root: true
    depends_on: []
    supersedes: []
    related: []
    conflicts_with: []
    ref: "../decisions.md#arch-001"
```

Los ADRs marcados `Supersedida por ARCH-XXX` llevan `status: SUPERSEDED` y `supersedes` apunta al reemplazante.

#### Qué NO cambia

| Archivo | ¿Cambiarlo? |
|:---|:---|
| `spec.md`, `architecture.md`, `qa.md`, `decision.md` de features existentes | No — el formato de artefactos es idéntico |
| `decisions.md` (ADRs históricos) | No — sigue siendo la fuente de verdad |
| `context.md`, `business-rules.md`, `glossary.md` | No — sin cambios de contrato |

#### Nota sobre visualización de gráficos

Los sistemas v3.2.0 son **archivos YAML tabulares**, no gráficos renderizados:
- **DAG** de workflows: describe la estructura de dependencias del pipeline; no se renderiza a gráfico
- **Knowledge Graph**: nodos indexados con aristas; se consulta por transitividad en el CLI con el Skill Manager
- **Métricas**: se agregan en `executions.yaml`; el Skill Manager genera un resumen en `aggregates.yaml` al cierre de sesión

No existe herramienta de renderizado visual incluida.

### 4.5 Migrar desde la v1.x del framework (proyecto heredado)

Aplica si tu proyecto se integró cuando `ai-agents` estaba en **v1.x/v2.0** (antes del salto a v3.0 y del actualizador de un comando). El submódulo ya apunta a este mismo repositorio, así que **no necesitas el script nuevo para migrar**: basta con actualizar el submódulo "a mano" una vez. El script `update-ai-agents.sh` vive **dentro** del submódulo, así que queda disponible automáticamente tras la actualización.

#### Paso 1 — Actualizar el submódulo al último commit

```bash
# Desde la raíz del proyecto
cd .ai/agents
git checkout main
git pull origin main        # trae el contenido de v3.x
cd ../..
git add .ai/agents
git commit -m "chore: update ai-agents submodule to v3.2.x"
```

> **Si usaste sparse-checkout:** la v1 documentaba `git sparse-checkout set agents templates` para traer "solo lo necesario". Esa estructura no existe en v3 (`agents/` pasó a llamarse `roles/`), y además sin `scripts/` no tendrás acceso al validador ni al actualizador. Desactívalo antes de actualizar:
> ```bash
> cd .ai/agents
> git sparse-checkout disable
> git checkout main && git pull origin main
> ```

#### Paso 2 — Activar los sistemas nuevos (memoria, métricas, knowledge graph)

```bash
# El setup-ide.sh v1.8.0 ahora existe dentro del submódulo actualizado.
# Forma interactiva (recomendada si quieres regenerar reglas IDE):
bash .ai/agents/scripts/setup-ide.sh
# Forma sin preguntas (solo crea seeds, no toca reglas IDE):
bash .ai/agents/scripts/setup-ide.sh --auto
```

Esto crea (idempotente, no toca lo existente): `.ai/memory/` con sus 4 seeds, `.ai/metrics/executions.yaml` y `.ai/knowledge-graph.yaml`.

#### Paso 3 — Regenerar las reglas IDE con las nuevas referencias

Si eliges la forma interactiva del Paso 2 (Opción 7 "Instalar TODOS"), los archivos `.cursorrules`, `CLAUDE.md`, etc. se regeneran apuntando a las rutas nuevas de v3 (`roles/`, `skills/`, `workflows/`).

#### Paso 4 — Adaptar las features existentes de v1

| Aspecto | v1.x | v3.x | ¿Qué cambia? |
|:---|:---|:---|:---|
| Archivos requeridos por feature | `spec.md`, `architecture.md`, `qa.md`, `decision.md` | + `ui-design.md` | Las features de v1 **fallan** la validación hasta tener `ui-design.md` |
| Nomenclatura | `FEAT-NNN-slug` | `FEAT-NNN-slug`, `BUG-NNN-slug`, `AUDIT-NNN-slug`, `REF-NNN-slug` | Sin cambios para FEAT/BUG; se agregan AUDIT y REF (estructura libre) |

```bash
# Para cada feature existente (si no lo tiene ya):
touch .ai/features/FEAT-NNN-slug/ui-design.md
```

Luego verifica con el validador:
```bash
bash .ai/agents/scripts/validate-project.sh
```
Los WARN de sistemas v3.2.0 desaparecen tras el Paso 2; los ERROR de `ui-design.md` desaparecen tras el Paso 4.

#### Qué NO es retroactivo

| Sistema | Situación |
|:---|:---|
| **Memoria** (`.ai/memory/`) | Arranca vacía; las sesiones de la era v1 no se recuperan |
| **Métricas** (`.ai/metrics/`) | Arrancan vacías; no miden ejecuciones pasadas |
| **Knowledge Graph** (`.ai/knowledge-graph.yaml`) | Arranca vacío; los ADRs de `decisions.md` se indexan solo con backfill manual (ver §4.4) |

#### A partir de aquí, las próximas actualizaciones

```bash
bash .ai/agents/scripts/update-ai-agents.sh                 # último commit
bash .ai/agents/scripts/update-ai-agents.sh v3.2.2          # pin a un tag
```

---

## 5. Configurar el Contexto del Proyecto

El archivo `.ai/context.md` es **la memoria del proyecto**. Es lo primero que leerá cualquier agente.

### 5.1 Crear el contexto inicial

```bash
# Copiar el template desde ai-agents
cp .ai/agents/templates/project-context.md .ai/context.md
```

Luego completar todos los campos del template. Ver [`templates/project-context.md`](../templates/project-context.md).

### 5.2 Secciones mínimas obligatorias

Un `context.md` mínimo efectivo debe tener:

```markdown
## Nombre y tipo del proyecto
## Stack tecnológico (con versiones)
## Módulos existentes y su estado
## Convenciones del proyecto (naming, estructura)
## Decisiones técnicas importantes
## Restricciones conocidas
```

### 5.3 Mantener el contexto actualizado

El `context.md` debe actualizarse cuando:

- [ ] Se agrega un nuevo módulo al proyecto
- [ ] Se toma una decisión técnica importante (agregar como ADR)
- [ ] Cambia el stack o una dependencia crítica
- [ ] Se incorpora un nuevo integrante al equipo
- [ ] Se completa una fase importante del proyecto

```bash
# El context.md SÍ debe estar en el repo del proyecto
git add .ai/context.md
git commit -m "docs: update project context - add bookings module"
```

---

## 6. Integración con IDEs de IA

Para que el asistente de IA en tu IDE entienda el flujo y los agentes de `ai-agents`, debes configurar las reglas correspondientes. Este repositorio incluye un instalador interactivo para automatizar este proceso.

### 6.1 Instanciación Automatizada (Recomendado)

Una vez que has añadido `ai-agents` como submódulo Git en `.ai/agents/`, ejecuta el siguiente comando desde la raíz de tu proyecto:

```bash
bash .ai/agents/scripts/setup-ide.sh
```

El script te ofrecerá:
*   Crear automáticamente las carpetas del sistema documental (`.ai/features/`, `.ai/archive/`, `.ai/sessions/`).
*   Inicializar archivos clave como `.ai/context.md` y `.ai/business-rules.md`.
*   Generar los archivos de reglas en la raíz de tu proyecto según el IDE que uses.

---

### 6.2 Archivos de Reglas Generados por IDE

A continuación se detallan los archivos de reglas que se pueden generar:

#### A. Cursor (`.cursorrules`)
Configura las reglas para Cursor (Composer y Chat). Instruye al modelo para que:
1. Consulte siempre la memoria permanente en `.ai/` (`context.md`, `business-rules.md`, `architecture.md`).
2. Adopte el rol correcto según la fase de desarrollo (Analyst, Architect, Tech Lead, Developer, QA).
3. Escriba las especificaciones y diseños técnicos de nuevas características estrictamente dentro de `.ai/features/FEAT-NNN-slug/`.

#### B. Claude Code (`CLAUDE.md`)
Reglas específicas para la herramienta CLI **Claude Code** de Anthropic. Contiene:
*   Comandos rápidos del proyecto (build, test, lint, format).
*   Instrucciones para respetar el sistema documental y leer `.ai/context.md` antes de escribir código.
*   Enrutamiento de tareas a través de los agentes definidos en `.ai/agents/roles/`.

#### C. Windsurf (`.windsurfrules`)
Configura el agente Cascade de Windsurf para que actúe según los roles y siga los workflows definidos en `.ai/agents/workflows/`.

#### D. Cline & Roo-Code (`.clinerules`)
Archivo de reglas para Cline/Roo-Code que restringe al agente para que no cree archivos redundantes y respete las restricciones documentales R1-R5.

#### E. GitHub Copilot (`.github/copilot-instructions.md`)
Reglas para guiar a GitHub Copilot Chat dentro de VS Code o Visual Studio, asegurando que siga las convenciones técnicas descritas en `.ai/context.md`.

#### F. Guía General (`AGENTS.md`)
Un documento general para humanos e IAs que explica cómo está organizado el sistema multi-agente en el proyecto, listando todos los agentes disponibles, los workflows y cómo invocar cada rol con prompts rápidos.

---

### 6.3 Configuración de VS Code (Opcional)

Si usas extensiones clásicas de IA en VS Code, puedes añadir a `.vscode/settings.json`:

```json
{
  "ai.contextFiles": [
    ".ai/context.md",
    "AGENTS.md",
    ".ai/agents/roles/prompt-guide.md"
  ]
}
```

---

## 7. Compartir Contexto entre Proyectos

### 7.1 El problema

Cuando tienes múltiples proyectos (LogiTrack, ControlFit, SaaS-X), cada uno tiene su propio `context.md`. Pero hay información que es común: tu stack preferido, tus convenciones globales, tus servicios compartidos.

### 7.2 Solución: `global-context.md` en ai-agents

Mantener en `ai-agents` un archivo de contexto global que aplica a todos tus proyectos:

```
ai-agents/
└── context/
    └── global-context.md    ← convenciones, stack base, servicios compartidos
```

```markdown
# global-context.md — aplica a todos los proyectos

## Stack base preferido
- Backend: NestJS + TypeScript
- Base de datos: PostgreSQL + Prisma
- Frontend: React + TypeScript + Vite
- Auth: Firebase Auth
- Deploy: Firebase / Vercel

## Convenciones globales
- Archivos: kebab-case
- Clases: PascalCase
- Variables: camelCase
- APIs: /api/v1/resources

## Servicios compartidos
- Autenticación: Firebase Auth (proyecto: mi-firebase-project)
- Pagos: Mercado Pago
- Email: SendGrid
```

Luego en cada proyecto, el `context.md` referencia el global:

```markdown
# .ai/context.md

> Ver contexto global: `.ai/agents/context/global-context.md`

## Contexto específico de este proyecto
[solo lo que es único de este proyecto]
```

### 7.3 Contexto por dominio

Si tienes proyectos en el mismo dominio (ej: varios proyectos de logística), puedes mantener contextos de dominio:

```
ai-agents/
└── context/
    ├── global-context.md
    ├── logistics-domain.md    ← reglas de negocio comunes de logística
    └── fitness-domain.md      ← reglas de negocio comunes de fitness/gym
```

---

## 8. Ejemplos por Tipo de Proyecto

### Proyecto SaaS (NestJS + React)

```bash
# Setup inicial
mkdir -p .ai
git submodule add https://github.com/ezequielmendoza-dev/ai-agents.git .ai/agents
cp .ai/agents/templates/project-context.md .ai/context.md

# Estructura final
mi-saas/
├── backend/              # NestJS
├── frontend/             # React
├── .ai/
│   ├── agents/           # Submodule ai-agents
│   └── context.md        # Contexto completado
└── .cursorrules
```

### Proyecto Firebase (App Móvil)

```bash
mi-app-movil/
├── lib/                  # Flutter / React Native
├── functions/            # Firebase Functions
├── .ai/
│   ├── agents/           # Submodule ai-agents
│   └── context.md
└── .cursorrules
```

### Script de Automatización

```bash
# Para proyectos simples, el submodule puede ser más ligero
# Usar sparse checkout para traer solo lo necesario (VERSIÓN v3.x)
git submodule add https://github.com/ezequielmendoza-dev/ai-agents.git .ai/agents
cd .ai/agents
git sparse-checkout init --cone
git sparse-checkout set roles templates workflows checklists scripts docs
 
# IMPORTANTE: si ya creaste el submodule con sparse-checkout en la era v1
# (patrón `agents templates`), actualiza el patrón ANTES de migrar a v3:
git sparse-checkout set roles templates workflows checklists scripts docs
```
> En v1 la carpeta de agentes era `agents/`; desde v2.x se llama `roles/`. Si usas sparse-checkout, el patrón debe listar los directorios actuales (roles, templates, workflows, checklists, scripts, docs). Ver §4.5 para la migración completa.

---

## 9. Troubleshooting

### El submodule aparece vacío después de clonar

```bash
# Solución
git submodule update --init --recursive
```

### El submodule está en estado "detached HEAD"

```bash
# Es normal — los submodules apuntan a un commit específico
# Para ver a qué commit apunta:
cd .ai/agents && git log --oneline -1

# Para actualizar al último:
git submodule update --remote .ai/agents
```

### Conflictos al hacer pull con cambios en el submodule

```bash
# Si el submodule tiene conflictos:
cd .ai/agents
git checkout main
git pull origin main
cd ../..
git add .ai/agents
git commit -m "chore: resolve submodule conflict"
```

### El IDE no encuentra los archivos del agente

Verificar que el submodule está inicializado:
```bash
ls .ai/agents/roles/  # debe listar los archivos .md
# Si está vacío:
git submodule update --init
```

---

*Documentación versión 1.0 — ai-agents library | [github.com/ezequielmendoza-dev/ai-agents](https://github.com/ezequielmendoza-dev/ai-agents)*
