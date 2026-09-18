# Configuración para Claude Code — Abbia OS

> **Importante:** Este archivo contiene instrucciones específicas para Claude Code CLI bajo el framework **Abbia OS**.
> Para la guía completa de roles, workflows y reglas documentales, consultar `AGENTS.md` en la raíz del proyecto.
> **Lema de Abbia:** *Layered Context, Structured Memory, Autonomous Delivery.*

---

## 🛠️ Comandos del Proyecto

Antes de ejecutar comandos, leer `.abbia/context.md` para conocer el stack y configuración exacta. Adaptar según el proyecto:

```bash
# Desarrollo
npm run dev          # Servidor de desarrollo

# Build
npm run build        # Compilación para producción

# Tests
npm run test         # Ejecutar tests unitarios
npm run test:watch   # Tests en modo watch

# Calidad
npm run lint         # Linter
npm run format       # Formatter
```

---

## 📋 Comportamiento Esperado en Abbia OS

1. **Leer contexto antes de actuar.** Comenzar leyendo `.abbia/context.md` y `.abbia/memory/context-snapshot.md`.
2. **Seguir el sistema de agentes.** Consultar `AGENTS.md` para conocer los roles, workflows y reglas documentales.
3. **Adoptar el rol correcto.** Según la fase de la tarea actual, leer y actuar conforme al rol en `.abbia/core/roles/`.
4. **Respetar la jerarquía documental.** No crear documentos fuera de `.abbia/initiatives/FEAT-NNN-slug/` salvo actualización de documentos permanentes.
5. **Cierre Mandatorio de Fase y Telemetría (Regla R6).** Al culminar cualquier tarea (`spec`, `ui-design`, `architecture`, `implement`, `qa`, `approval`, `deploy`), **ES OBLIGATORIO ejecutar en la terminal**:
   ```bash
   bash .abbia/core/scripts/finish-phase.sh <INICIATIVA> <FASE> <ROL> \
     --model <MODELO> --tokens-in <TOKENS_IN> --tokens-out <TOKENS_OUT> \
     --duration <SEGUNDOS> --source measured
   ```
   *O alternativamente vía CLI wrapper:*
   ```bash
   ./abbia finish <INICIATIVA> <FASE> <ROL> --model <MODELO> --tokens-in <TOKENS_IN> --tokens-out <TOKENS_OUT> --duration <SEGUNDOS> --source measured
   ```

---

## ⚙️ Reglas Específicas de Claude Code

### Ejecución de Comandos
- Antes de ejecutar un comando destructivo o irreversible, **explicar qué se va a hacer y por qué**.
- Para operaciones de base de datos o deploy, **solicitar confirmación explícita** antes de proceder.
- Preferir comandos con output limitado. Usar `--quiet` o pipes cuando sea apropiado.

### Gestión de Archivos
- Al modificar archivos existentes, usar ediciones quirúrgicas (no reescribir archivos completos).
- Verificar que los archivos existan antes de intentar editarlos.
- Crear directorios intermedios cuando sea necesario.

### Memoria de Sesión
- Si el usuario define memorias con `/memory`, respetar esas instrucciones por encima de las reglas generales.
- Las memorias de sesión no deben contradecir las reglas documentales (R1-R6) definidas en `AGENTS.md`.
