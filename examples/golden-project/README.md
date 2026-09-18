# 🌟 Golden Project — Ejemplo de Referencia de ai-agents OS

Este subproyecto sirve como **referencia canónica** de cómo se estructura e implementa un proyecto de software real utilizando el framework `ai-agents` y la metodología **Specification-Driven Development (SDD)**.

---

## 🎯 ¿Qué demuestra este proyecto?

1. **Estructura Documental `.ai/`:** Muestra la memoria permanente en la raíz de `.ai/` (`context.md`, `business-rules.md`, `architecture.md`, `decisions.md`, `knowledge-graph.yaml`, `glossary.md`).
2. **Ciclo Completo Archivada (`.ai/archive/FEAT-001-user-auth`):**
   - `spec.md` (especificación funcional con criterios Gherkin).
   - `ui-design.md` (diseño visual de interfaz y accesibilidad).
   - `architecture.md` (diseño técnico de contratos y endpoints).
   - `decision.md` (registro de decisiones locales).
   - `qa.md` (reporte de pruebas con veredicto `APROBADO`).
3. **Iniciativa en Progreso (`.ai/features/FEAT-002-order-checkout`):**
   - `spec.md` y `decision.md` creados al bootstrap sin esqueletos prematuros.
4. **Memoria y Telemetría:**
   - `.ai/memory/workflow-log.md` con historial de sesiones.
   - `.ai/memory/context-snapshot.md` generado automáticamente.
   - `.ai/metrics/executions.yaml` con telemetría de tokens y duraciones.

---

## 🔍 Cómo verificar este proyecto

Desde la raíz del repositorio:
```bash
# Validar cumplimiento de reglas documentales
bash scripts/validate-project.sh

# Ejecutar la suite completa de tests automatizados
bash tests/test-runner.sh
```
