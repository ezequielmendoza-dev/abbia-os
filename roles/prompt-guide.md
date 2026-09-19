# Guía de Prompts — Cómo Usar los Agentes Efectivamente

> **Para quién:** Desarrolladores que usan este repositorio  
> **Objetivo:** Obtener el máximo valor de cada agente  
> **Lectura recomendada:** Antes de usar cualquier agente por primera vez

---

## El Principio Fundamental

Un agente es tan bueno como el contexto que le das.

La diferencia entre un output genérico e inútil y uno preciso y accionable está **completamente en tu prompt**. Los agentes tienen la capacidad — tú debes activarla con el contexto correcto.

---

## Modos de Interacción con Abbia OS

Tienes dos formas principales de interactuar con el sistema según el nivel de control que prefieras:

### 🎙️ Modo 1: Orquestación Directa por Nombre ("Abbia, ...")
Ideal para comenzar una nueva idea o cuando prefieres que el framework te guíe paso a paso:
```text
Abbia, debemos crear una feature para autenticación con Google y Magic Links.
```
**Qué hace Abbia automáticamente:**
1. Asume su identidad como orquestador del sistema.
2. Reconoce que es una nueva iniciativa y activa el rol de **Product Analyst**.
3. Realiza el *Discovery* y te formula preguntas de clarificación (*Protocolo de Clarificación Proactiva*).
4. Genera `spec.md` y te propone el siguiente paso del pipeline SDD.

---

### 🎯 Modo 2: Activación Quirúrgica por Rol
Ideal para tareas puntuales, optimizar tokens y delegar una fase específica a un rol especializado:

```markdown
## 1. Activación del agente
"Actúa como el agente [Nombre] definido en roles/[archivo].md"

## 2. Identificación de la feature o tarea activa
"Nuestra feature/bug actual es: [FEAT-NNN-slug / BUG-NNN-slug]"

## 3. Tarea específica
"[descripción clara de lo que necesitas que el agente haga]"

## 4. Referencias a archivos o inputs concretos (opcional)
"Usa como entrada el archivo [ruta/al/archivo o usa @archivo en tu IDE]"
```

---

## Prompts por Agente

### 🔍 Product Analyst

#### Prompt estándar — análisis de nueva feature
```
Actúa como el agente Product Analyst definido en roles/analyst.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

Requerimiento a analizar:
"Quiero que los pasajeros puedan calificar al conductor después de cada viaje.
La calificación es con estrellas del 1 al 5 y un comentario opcional."
```

#### Prompt de Bootstrap / Auto-Contextualización de un Proyecto
```
Actúa como el agente Product Analyst definido en roles/analyst.md y genera el archivo `.abbia/context.md` de este proyecto basándote en la plantilla `.ai/agents/templates/project-context.md` tras escanear la estructura y archivos de configuración.
```

#### Prompt con contexto de archivo
```
Actúa como el agente Product Analyst definido en roles/analyst.md.
Nuestra feature actual es: FEAT-013-cancelar-reserva.

Historia de usuario:
Como pasajero, quiero poder cancelar mi reserva desde la app para no tener que llamar al operador.

Restricciones conocidas:
- El reembolso debe respetar la política de cancelación definida por el operador
- Los conductores no deben ver las cancelaciones en tiempo real (solo al inicio del viaje)
```

#### Prompt de re-análisis por feedback del Tech Lead
```
Actúa como el agente Product Analyst definido en roles/analyst.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

El Tech Lead rechazó la especificación en .abbia/initiatives/FEAT-012-calificacion-viajes/spec.md con el siguiente feedback:
[Escribir o referenciar el feedback recibido]

Por favor, revisa el archivo de especificación original y corrige los puntos señalados.
```

---

### 🏗️ Software Architect

#### Prompt estándar
```
Actúa como el agente Software Architect definido en roles/architect.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

Lee la especificación funcional aprobada en .abbia/initiatives/FEAT-012-calificacion-viajes/spec.md.

Restricciones técnicas adicionales:
- Debe funcionar con la base de datos PostgreSQL existente (sin cambiar el motor)
- El módulo de pagos ya usa Mercado Pago — reutilizar si es posible
```

#### Prompt con contexto de arquitectura existente
```
Actúa como el agente Software Architect definido en roles/architect.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

Lee la arquitectura actual en .abbia/architecture.md y la especificación funcional en .abbia/initiatives/FEAT-012-calificacion-viajes/spec.md. Diseña la solución técnica para esta feature.
```

---

### ⚖️ Tech Lead

#### Prompt de revisión de feature-spec
```
Actúa como el agente Tech Lead definido en roles/tech-lead.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

Por favor, lee y revisa la especificación funcional en .abbia/initiatives/FEAT-012-calificacion-viajes/spec.md. Evalúa completitud, consistencia y riesgos.
```

#### Prompt de revisión de diseño técnico
```
Actúa como el agente Tech Lead definido en roles/tech-lead.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

Por favor, revisa el diseño técnico en .abbia/initiatives/FEAT-012-calificacion-viajes/architecture.md comparándolo con la especificación funcional en .abbia/initiatives/FEAT-012-calificacion-viajes/spec.md. Evalúa solidez, coherencia con la arquitectura existente y riesgos técnicos.
```

#### Prompt de decisión ante conflicto
```
Actúa como el agente Tech Lead definido en roles/tech-lead.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

Hay un conflicto entre la especificación (.abbia/initiatives/FEAT-012-calificacion-viajes/spec.md) y la arquitectura (.abbia/initiatives/FEAT-012-calificacion-viajes/architecture.md):
- El Analyst especifica que [X]
- El Architect propone implementarlo como [Y]
- El Developer señala que [Y] es técnicamente complejo y propone [Z]

Por favor, lee los documentos e indica cuál es el camino correcto y qué agente debe actuar a continuación.
```

---

### 💻 Senior Developer

#### Prompt estándar de implementación
```
Actúa como el agente Senior Developer definido en roles/developer.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

Por favor, lee la tarea técnica en .abbia/initiatives/FEAT-012-calificacion-viajes/task.md y el diseño técnico en .abbia/initiatives/FEAT-012-calificacion-viajes/architecture.md, e impleméntala manteniendo la consistencia con el resto del proyecto.
```

#### Prompt de corrección de bug
```
Actúa como el agente Senior Developer definido en roles/developer.md.
Nuestra feature actual es: BUG-005-calificacion-incompleta.

Por favor, lee el reporte de bug en .abbia/initiatives/BUG-005-calificacion-incompleta/bug-report.md e implementa la corrección en el código correspondiente.
```

---

### 🧪 QA Engineer

#### Prompt estándar de validación
```
Actúa como el agente QA Engineer definido en roles/qa.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

Lee la especificación funcional en .abbia/initiatives/FEAT-012-calificacion-viajes/spec.md. El Developer ha completado la implementación. Por favor, valida los cambios y genera el reporte de QA en .abbia/initiatives/FEAT-012-calificacion-viajes/qa.md, haciendo foco especial en la validación de la seguridad.
```

#### Prompt de re-verificación post bug-fix
```
Actúa como el agente QA Engineer definido en roles/qa.md.
Nuestra feature actual es: FEAT-012-calificacion-viajes.

El Developer indica que corrigió los bugs reportados en .abbia/initiatives/FEAT-012-calificacion-viajes/qa.md. Por favor, lee ese reporte anterior y verifica:
1. Que los bugs fueron efectivamente corregidos en el código.
2. Que la corrección no introdujo regresiones.
```

---

## Errores Comunes y Cómo Evitarlos

### ❌ Error 1: Tener un archivo `.abbia/context.md` desactualizado o vacío
Dado que los agentes leen automáticamente `.abbia/context.md` del workspace para entender el stack, las convenciones y la estructura, no tener este archivo o mantenerlo desactualizado provocará que el agente responda con información genérica.

❌ Mal:
Iniciar un prompt sin haber completado o actualizado `.abbia/context.md` primero.

✅ Bien:
Mantener `.abbia/context.md` como la fuente de verdad actualizada en el repositorio. Al invocar al agente, este lo leerá de forma implícita e inmediata sin necesidad de pasarlo en el prompt.

### ❌ Error 2: Activar el agente incorrecto
```
❌ Mal: Pedirle al Developer que diseñe la arquitectura
❌ Mal: Pedirle al Analyst que proponga tablas de base de datos
❌ Mal: Pedirle al Architect que escriba el código

✅ Bien: Seguir el pipeline. Cada agente en su momento.
```

### ❌ Error 3: Inputs demasiado vagos
```
❌ Mal:
"Revisa el código y dime si está bien."

✅ Bien:
"Actúa como QA Engineer. La feature es reserva de asientos (FEAT-015).
Los criterios de aceptación son: [lista]. El Developer implementó: [descripción].
Valida especialmente los casos de concurrencia."
```

### ❌ Error 4: Saltarse el pipeline
```
❌ Mal: Ir directo al Developer sin feature-spec ni arch-spec
❌ Mal: Hacer QA sin tener los criterios de aceptación documentados

✅ Bien: Analyst → Architect → Tech Lead → Developer → QA
```

---

## Tips Avanzados

### Tip 1: Cadena de agentes en una sola sesión
Puedes activar múltiples agentes en secuencia en la misma conversación:
```
1. "Actúa como Analyst. Analiza este requerimiento: [X]"
   → El AI produce la feature-spec

2. "Ahora actúa como Architect. Diseña la solución técnica para la spec anterior."
   → El AI produce el arch-spec

3. "Ahora actúa como Tech Lead. Revisa ambos documentos anteriores."
   → El AI produce la revisión
```

### Tip 2: Dar el archivo completo del agente como contexto
En algunos IDEs (Cursor, Windsurf) puedes hacer `@roles/analyst.md` para incluir el agente completo automáticamente.

### Tip 3: Mantener la memoria del proyecto actualizada
La diferencia más grande en la calidad del output viene de tener `.abbia/context.md` bien documentado y actualizado. La IA lo lee de forma transparente al inicializarse gracias a las reglas del IDE (`.cursorrules`, `CLAUDE.md`, etc.), por lo que no es necesario copiarlo ni pegarlo en el chat.

### Tip 4: Los agentes preguntan antes de asumir (por diseño)
Todos los agentes tienen un **Protocolo de Clarificación Proactiva** integrado en su proceso de pensamiento. Antes de producir su output, evalúan si existen ambigüedades de negocio o alcance funcional y, si las encuentran, se detienen y te formulan preguntas concisas. No necesitas indicárselo en el prompt — lo hacen de forma autónoma.

Las preguntas que puede hacer un agente son siempre sobre:
- Lógica de negocio y reglas del dominio
- Alcance funcional y prioridades del proyecto
- Restricciones comerciales o del entorno

Las decisiones técnicas dentro de su área de expertise las toman sin consultar.

### Tip 5: Cierre Mandatorio de Fase con Telemetría (Regla R6)
Cada vez que un agente concluye su fase de trabajo, **debe ejecutarse en terminal el cierre con sus flags de telemetría**:
```bash
bash .abbia/core/scripts/finish-phase.sh <INICIATIVA> <FASE> <ROL> \
  --model <MODELO> --tokens-in <TOKENS_IN> --tokens-out <TOKENS_OUT> \
  --duration <SEGUNDOS> --source measured [opciones]
```

**Flags disponibles y recomendados:**

| Flag | Descripción | Valor por defecto |
|:---|:---|:---|
| `--model <NOMBRE>` | Modelo de IA utilizado (ej: `deepseek/deepseek-r1`, `gemini-3.7-flash`, `claude-3.7-sonnet`) | `null` |
| `--provider <NOMBRE>` | Entorno/IDE (ej: `opencode`, `antigravity`, `cursor`, `claude-code`) | Auto-detectado |
| `--env <local\|staging\|production>` | Entorno de despliegue/validación (local, staging, prod) | Auto-inferido s/ fase |
| `--tokens-in <N>` | Tokens de entrada consumidos en la sesión | `null` |
| `--tokens-out <N>` | Tokens de salida generados en la sesión | `null` |
| `--duration <N>` | Duración de la fase en segundos | `null` |
| `--source measured\|estimate` | `measured` si los tokens son reales, `estimate` si son estimados | `estimate` |
| `--verdict PASS\|FAIL\|APROBADO\|RECHAZADO` | Solo para fases gate (qa, approval, deploy) | `null` |
| `--mode rapido\|estandar\|profundo` | Modo de ejecución del DAG | `estandar` |
| `--attempts <N>` | Número de intentos (incluye back-edges) | `1` |

**Fases canónicas del DAG** (usar exactamente estos nombres):
`analysis` · `discovery` · `ui-design` · `architecture` · `tech-review-1` · `tech-review-2` · `implement` · `tasks` · `qa` · `approval` · `deploy`

**Inferencia y Auto-detección:**
- **`target_env`:** Se auto-asigna `local` para análisis/desarrollo, `staging` para QA, y `production` para release.
- **`git_branch`:** Se auto-detecta la rama activa de Git en el momento de cierre.
- **`provider`:** Se auto-detecta si estás en OpenCode, Antigravity, Cursor, etc.

**Ejemplo completo:**
```bash
bash .abbia/core/scripts/finish-phase.sh FEAT-113 architecture architect \
  --model "deepseek/deepseek-r1" --provider "opencode" --env "local" \
  --tokens-in 22000 --tokens-out 6500 \
  --duration 900 --source measured
```

Esto garantiza automáticamente:
1. **Memoria de Workflow:** Registro append-only en `.abbia/memory/workflow-log.md`.
2. **Telemetría Veraz:** Registro exacto de ejecución en `.abbia/metrics/executions.yaml` (con modelo, entorno, rama y tokens).
3. **Aggregates:** Regeneración de `.abbia/metrics/aggregates.yaml` con estadísticas por fase, rol, modelo, entorno e iniciativa.
4. **Snapshot Actualizado:** Regeneración inmediata de `.abbia/memory/context-snapshot.md` con resumen de métricas.

---

*Guía versión 3.5.1 — ai-agents library | github.com/ezequielmendoza-dev/abbia-os*
