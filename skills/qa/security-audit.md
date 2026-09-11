---
id: security-audit
category: qa
aliases: [security, audit-security, security-review]
type: method
version: 1.0
---

# Security Audit

> Metodología para auditar la postura de seguridad de un sistema: autenticación, inyección, secretos, dependencias y datos.

---

## Cuándo Usar Esta Skill
- Al revisar código antes de un release con superficie de ataque nueva.
- Al auditar un sistema existente con exposición pública.
- Al diseñar con requisitos de cumplimiento (GDPR, SOC 2, PCI).

## Principios Fundamentales
1. **Defensa en Profundidad:** Varias capas independientes de control (validación, authN, authZ, rate limiting, monitoreo), ninguna supone que la anterior es infalible.
2. **Fail-Closed:** Ante la duda, denegar el acceso o abortar la operación, nunca continuar con permisos implícitos.
3. **Mínimo Privilegio:** Cada servicio, rol y token tiene solo los permisos que necesita, por el menor tiempo posible.

## Checklist de Auditoría

### Autenticación y Autorización
- [ ] Contraseñas con hash adaptativo (argon2, bcrypt) y nunca almacenadas en texto plano.
- [ ] MFA habilitado para acciones sensibles y administración.
- [ ] Sesiones con expiración, rotación de tokens y revocación.
- [ ] Chequeo de autorización por recurso, no solo por endpoint (IDOR).
- [ ] Tokens JWT: firma validada, algoritmo restringido, expiración corta, no incluir datos sensibles.

### Validación de Entrada y Salida
- [ ] Todas las entradas validadas en el límite (schemas, tipos, longitudes).
- [ ] SQL: solo parámetros preparados, nunca concatenación.
- [ ] Datos del usuario escapeados para el contexto de presentación (XSS).
- [ ] Headers de seguridad: `Content-Security-Policy`, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`.
- [ ] Manipulación de contenido: validación de uploads por tipo real, no por extensión; tamaño y política de ejecución.

### Secretos y Dependencias
- [ ] Sin secretos en el repositorio (verificado por escáner en CI: gitleaks, trufflehog).
- [ ] Rotación de claves documentada y posible.
- [ ] Dependencias auditadas (Dependabot/renovate, `npm audit`, `pip-audit`) con gates en CI.
- [ ] Imágenes base de contenedores escaneadas (Trivy, Grype).

### Datos y Cumplimiento
- [ ] Datos en tránsito cifrados (TLS) al menos en producción y staging.
- [ ] Datos sensibles en reposo cifrados (disk/field level según riesgo).
- [ ] Minificación de datos personales: solo lo necesario para la función.
- [ ] Política de retención y borrado de datos personales.

### Infraestructura
- [ ] Puertos expuestos mínimos; solo lo necesario al exterior.
- [ ] Rate limiting en endpoints de auth y acciones costosas.
- [ ] Logs de auditoría de acciones de administración y alto riesgo.
- [ ] Plan de respuesta a incidentes (qué apagar primero, cómo comunicar).

## Modelado de Amenazas (Threat Modeling Liviano)

Para cada funcionalidad crítica, evaluar:
1. **Qué puede salir mal:** Del entrevistado, del atacante, del proceso.
2. **Quién es el atacante:** Nivel de acceso, recursos, motivación.
3. **Impacto si se concreta:** Confidencialidad, integridad, disponibilidad.
4. **Mitigaciones existentes y faltantes:** https://owasp.org/www-project-threat-modeling/

## Anti-Patrones
- ❌ **Seguridad solo en el frontend:** Ocultar botones o validar en el cliente da sensación de seguridad pero nada protege.
- ❌ **Librerías de confianza ciega:** Dependencias famosas con CVEs sin actualizar (log4j, etc). Auditar y actualizar con política.
- ❌ **Logs con datos sensibles:** Registrar passwords, tokens, PII en logs. Igual de peliagudo: logs de acceso con todo el request body.
- ❌ **Security by obscurity:** Esconder endpoints o IDs "porque nadie los encontrará".
- ❌ **Ignorar el faill-safe:** Auditorías estrictas que bloquean la operación normal pero son opcionales en producción.

## Integración con Otros Skills
- Complementa la lista de verificaciones con [`devops-pipeline`](../workflow/devops-pipeline.md) para gates de seguridad en CI.
- Se aplica al código con [`code-review`](../development/code-review.md) en los PRs.
- Con [`requirements-discovery`](../analysis/requirements-discovery.md) para capturar requisitos de seguridad en la especificación.