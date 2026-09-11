---
id: devops-pipeline
category: workflow
aliases: [ci-cd, devops, deployment]
type: method
version: 1.0
---

# DevOps Pipeline

> Metodología para diseñar y operar pipelines de CI/CD robustos: integración continua, despliegue continuo, entornos y observabilidad.

---

## Cuándo Usar Esta Skill
- Al diseñar la estrategia de CI/CD de un proyecto nuevo.
- Al revisar un pipeline existente con fallos frecuentes o deployments manuales.
- Antes de un release, para validar que el pipeline está listo para desplegar sin fricción.

## Principios Fundamentales
1. **Trunk-Based Development:** Ramas cortas, integración frecuente a `main`, feature flags para entregas graduales.
2. **El Código y el Pipeline son el Mismo Artefacto:** La config de CI/CD vive versionada en el repo (IaC), nunca en un portal con clicks.
3. **Un Binario, Muchos Entornos:** Buildear una vez, promover el mismo artefacto por los entornos (dev → staging → prod). Evitar rebuilds por ambiente.

## Diseño del Pipeline de CI

Etapas típicas en CI (sobre cada push/PR):

| Etapa | Qué hace | Velocidad |
|:---|:---|:---|
| Lint | Estilos y reglas estáticas (ESLint, Ruff, golangci-lint) | Segundos |
| Typecheck/Compile | Errores de tipo y compilación | Segundos |
| Unit tests | Cobertura de lógica pura, sin I/O | Segundos-minutos |
| Build | Compilar y empaquetar artefacto | Minutos |
| Integration/E2E | Tests con infraestructura (botan/BBDD/Services) | 10-30 min |
| Security scan | Dependency audit, secretos, SAST | Minutos |
| Artefacto | Publicar imagen/binario/paquete versionado | Minutos |

- **Gate estricto:** Derecha de la rama, izquierda del merge: ningún PR a `main` entra si una etapa de CI falla.
- **Cache e incrementalidad:** Cachear dependencias y builds (layer cache de Docker, `node_modules`, `.gradle`). Compilar solo lo que cambió.

## Diseño del Pipeline de CD

- **Deploy por Promoción:** El artefacto subido en CI se promueve: `dev → staging → prod`. El código no se recompila por entorno.
- **Rollback de 1 comando:** Deploy con release inmutables + re-deploy del artefacto anterior versionado.
- **Zero-Downtime:** Blue/green, canary o rolling según criticidad. Siempre prever cómo deshacer.
- **Feature Flags:** Permiten entregar código a producción sin exponerlo al usuario (deploy ≠ release).

## Entornos y Datos

- **Paridad de Entornos:** staging debe imitar producción lo más posible (versiones, config, secretos dummy, datos sintéticos con la misma morfología).
- **Probidad de Datos:** Nunca usar datos de producción reales en entornos de prueba sin anonimizar.
- **Ephemeral Preview Environments:** Para PRs (Vercel, Render, ArgoCD-style) cuando el proyecto lo permite; dan feedback visual temprano.

## Observabilidad (Impulsa la confianza para desplegar)

- **Logs estructurados:** JSON, con `requestId`/`traceId` correlacionables.
- **Métricas:** Latencia, errores (RED), tasas de uso. Centralizadas (Prometheus/Grafana, Datadog, New Relic).
- **Trazas distribuidas:** Para sistemas multi-servicio (OTel).
- **Alertas accionables:** Alertas sobre síntomas (SLO), no sobre tecnicismos. Cada alerta debe tener un runbook.

## Anti-Patrones
- ❌ **Build por entorno:** Compilar en dev y recompilar en prod. Promover el mismo artefacto.
- ❌ **Deploy manual:** Cliquear en dashboards o ejecutar pasos a mano "porque son solo 3 comandos". Automatizar.
- ❌ **CI sin gates:** Pipeline que "corre" pero que permite merge con tests rojos o lint con errores.
- ❌ **Secrets en el pipeline file:** Claves hardcodeadas en YAML. Usar secret managers del proveedor.
- ❌ **Stage "long-lived" sin limpieza:** Entornos de preview que se acumulan y nadie apaga.
- ❌ **El config en otro lado:** Pipeline configurado solo en la UI de la nube, imposible de auditar o replicar.

## Integración con Otros Skills
- Consume [`release-readiness`](release-readiness.md) como checklist previo al despliegue.
- Se coordina con [`testing-automation`](../qa/testing-automation.md) para la etapa de tests en CI.
- Con [`security-audit`](../qa/security-audit.md) para las gates de seguridad en el pipeline.
- Con [`performance-tuning`](../architecture/performance-tuning.md) para criterios de desempeño en staging.