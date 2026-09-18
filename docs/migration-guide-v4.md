# Guía de Migración: De `ai-agents` (.ai/) a Abbia OS v4.0.0 (.abbia/)

Esta guía detalla el proceso para actualizar cualquier proyecto que consuma `ai-agents` (o `.stratum/`) a la nueva versión mayor **Abbia OS v4.0.0**.

---

## 🚀 ¿Por qué migrar a Abbia OS?

1. **Estructura Modular e Inequívoca:** Cambia la carpeta genérica `.ai/` por `.abbia/`, y el submódulo de `.ai/agents` a `.abbia/core`.
2. **CLI Wrapper Incluido (`./abbia`):** Ejecuta comandos de forma rápida desde la raíz sin recordar rutas largas de bash.
3. **Roles con Context Contracts Renovados:** Nuevas identidades de agentes con contratos estrictos de contexto y telemetría automática.
4. **Soporte de Retrocompatibilidad:** Tus scripts y workflows continuarán funcionando con normalidad.

---

## ⚡ Opción A: Migración Automática en 1 Paso (Recomendada)

Si ya tienes el submódulo en tu proyecto, simplemente ejecuta:

```bash
# 1. Actualizar el submódulo al core de Abbia OS
git submodule update --remote

# 2. Ejecutar la herramienta de migración
bash .ai/agents/scripts/migrate-to-abbia.sh
```

El script se encargará automáticamente de:
- Renombrar `.ai/` o `.stratum/` a `.abbia/`
- Mover `.ai/features/` a `.abbia/initiatives/`
- Mover el submódulo a `.abbia/core/` y actualizar `.gitmodules`
- Actualizar reglas de `.gitignore` y `.gitattributes`
- Instalar el CLI wrapper `./abbia`
- Regenerar reglas de IDEs (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`, etc.)
- Validar la consistencia total del proyecto

---

## 🛠️ Opción B: Migración Manual Paso a Paso

Si prefieres realizar el proceso manualmente:

### 1. Mover la carpeta de configuración
```bash
mv .ai .abbia
mv .abbia/features .abbia/initiatives
mv .abbia/agents .abbia/core
```

### 2. Actualizar `.gitmodules`
Edita `.gitmodules` para cambiar la ruta:
```ini
[submodule ".abbia/core"]
    path = .abbia/core
    url = https://github.com/ezequielmendoza-dev/abbia-os.git
```

### 3. Actualizar `.gitignore` y `.gitattributes`
En `.gitignore`:
```diff
- .ai/sessions/
- .ai/dashboard.html
- .ai/memory/context-snapshot.md
- .ai/metrics/aggregates.yaml
+ .abbia/sessions/
+ .abbia/dashboard.html
+ .abbia/memory/context-snapshot.md
+ .abbia/metrics/aggregates.yaml
```

En `.gitattributes`:
```diff
- .ai/memory/workflow-log.md merge=union
- .ai/metrics/executions.yaml merge=union
+ .abbia/memory/workflow-log.md merge=union
+ .abbia/metrics/executions.yaml merge=union
```

### 4. Regenerar Reglas de IDEs y Validar
```bash
bash .abbia/core/scripts/setup-ide.sh --auto
bash .abbia/core/scripts/validate-project.sh
```

---

## 💡 Uso Diario con el CLI Wrapper `./abbia`

Una vez migrado, puedes usar el CLI `./abbia` desde la raíz de tu proyecto:

```bash
# Crear nueva feature
./abbia new FEAT 001 login-seguro

# Cerrar fase con telemetría
./abbia finish FEAT-001 spec analyst --tokens-in 3000 --tokens-out 1000 --duration 120 --source measured

# Validar estado del proyecto
./abbia validate

# Abrir el dashboard interactivo
./abbia dashboard
```
