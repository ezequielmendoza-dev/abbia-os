# Feature Specification Template

> **Uso:** Completar este template antes de que el Architect comience su trabajo.  
> **Responsable:** Product Analyst  
> **Revisado por:** Tech Lead

---

## Metadata

| Campo | Valor |
|-------|-------|
| **Proyecto** | `[nombre-del-proyecto]` |
| **Feature ID** | `FEAT-XXX` |
| **Fase Previa** | `[Ver discovery.md / No aplica]` |
| **Fecha** | `YYYY-MM-DD` |
| **Versión** | `1.0` |
| **Estado** | `Discovery / Draft / Reviewed / Approved / In Progress / Done / Archived` |
| **Analista** | `[nombre]` |
| **Stakeholder** | `[nombre]` |

---

## 1. Objetivo

> Descripción breve y clara del problema que esta feature resuelve.

**Ejemplo:**
> Permitir que los pasajeros reserven asientos en viajes programados, con confirmación en tiempo real y posibilidad de cancelación con reembolso automático.

---

## 2. Contexto de Negocio

> ¿Por qué se necesita esta feature? ¿Qué problema de negocio resuelve?

**Ejemplo:**
> Actualmente los pasajeros deben llamar por teléfono para reservar, lo que genera fricciones, errores y demoras. Esta feature digitaliza el proceso y reduce el trabajo manual de los operadores.

---

## 3. Actores

| Actor | Rol en la Feature |
|-------|-------------------|
| `[Actor 1]` | `[descripción]` |
| `[Actor 2]` | `[descripción]` |

**Ejemplo:**

| Actor | Rol en la Feature |
|-------|-------------------|
| Pasajero | Busca viajes, reserva asientos, cancela reservas |
| Conductor | Ve los pasajeros confirmados en su viaje |
| Operador | Gestiona conflictos y reembolsos manuales |
| Sistema | Procesa pagos, envía notificaciones, actualiza disponibilidad |

---

## 4. Casos de Uso

### CU-01: [Nombre del Caso de Uso]

**Actor:** `[actor principal]`  
**Precondición:** `[estado inicial requerido]`  
**Flujo Principal:**

1. El actor hace X
2. El sistema responde con Y
3. El actor confirma Z

**Flujo Alternativo:**
- Si X no está disponible → mostrar mensaje Y

**Postcondición:** `[estado final del sistema]`

---

### CU-02: [Nombre del Caso de Uso]

*(Repetir estructura para cada caso de uso)*

---

## 5. Reglas de Negocio

| ID | Regla |
|----|-------|
| RN-01 | `[descripción de la regla]` |
| RN-02 | `[descripción de la regla]` |

**Ejemplo:**

| ID | Regla |
|----|-------|
| RN-01 | Un pasajero no puede reservar más de 4 asientos en el mismo viaje |
| RN-02 | La cancelación es gratuita hasta 2 horas antes del viaje |
| RN-03 | Pasado el tiempo límite, se aplica una penalidad del 20% |
| RN-04 | No se pueden reservar asientos en viajes con estado "CANCELADO" |

---

## 6. Casos Borde

| ID | Escenario | Comportamiento Esperado |
|----|-----------|------------------------|
| CB-01 | `[escenario]` | `[respuesta esperada]` |
| CB-02 | `[escenario]` | `[respuesta esperada]` |

**Ejemplo:**

| ID | Escenario | Comportamiento Esperado |
|----|-----------|------------------------|
| CB-01 | El último asiento es reservado simultáneamente por dos usuarios | Solo uno confirma; el otro recibe error de disponibilidad |
| CB-02 | El usuario reserva y el viaje es cancelado por el operador | Reembolso automático del 100% |
| CB-03 | El usuario intenta reservar sin método de pago registrado | Redirigir a configuración de pago antes de continuar |

---

## 7. Impacto en Funcionalidades Existentes

> ¿Qué partes del sistema existente se ven afectadas?

**Ejemplo:**
- **Módulo de Viajes:** Deberá exponer disponibilidad de asientos en tiempo real
- **Módulo de Pagos:** Se integra el flujo de cobro y reembolso
- **Módulo de Notificaciones:** Se agregan nuevos tipos de notificación (reserva confirmada, cancelación)
- **Panel de Conductor:** Nuevo tab para ver pasajeros confirmados

---

## 8. Riesgos Funcionales

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|----|--------|-------------|---------|------------|
| RF-01 | `[riesgo]` | Alta/Media/Baja | Alto/Medio/Bajo | `[acción]` |

**Ejemplo:**

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|----|--------|-------------|---------|------------|
| RF-01 | Condición de carrera en reserva del último asiento | Alta | Alto | Implementar bloqueo optimista o transacción atómica |
| RF-02 | El usuario no completa el pago y el asiento queda bloqueado | Media | Medio | Timeout de reserva pendiente de 10 minutos |

---

## 9. Criterios de Aceptación

> ¿Cómo se verifica que la feature está correctamente implementada?

- [ ] El usuario puede buscar viajes disponibles por fecha y destino
- [ ] El usuario puede reservar un asiento y recibe confirmación
- [ ] La disponibilidad se actualiza en tiempo real
- [ ] La cancelación aplica las reglas de negocio correctamente
- [ ] El conductor ve la lista de pasajeros actualizada

---

## 10. Preguntas Abiertas

| ID | Pregunta | Responsable | Estado |
|----|----------|-------------|--------|
| PA-01 | `[pregunta]` | `[nombre]` | Pendiente / Respondida |

**Ejemplo:**

| ID | Pregunta | Responsable | Estado |
|----|----------|-------------|--------|
| PA-01 | ¿Se permite reservar asientos para otras personas? | Product Owner | Pendiente |
| PA-02 | ¿El reembolso es automático o requiere aprobación manual? | Finance Team | Respondida: Automático |

---

## 11. Anexos

> Links a mockups, documentación relacionada, conversaciones de referencia, etc.

- [Mockup en Figma](https://figma.com/...)
- [Ticket en Jira](https://jira.com/...)
- [Conversación de referencia](#)

---

*Feature spec template v2.0 — ai-agents framework | github.com/ezequielmendoza-dev/abbia-os*
