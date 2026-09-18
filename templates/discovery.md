# Discovery Template

> **Uso:** El Product Analyst completa este documento cuando detecta ambigüedades críticas que impiden producir una spec completa.  
> **Responsable:** Product Analyst  
> **Precede a:** `spec.md`  
> **Aprobación:** No requiere aprobación formal — es un artefacto de trabajo interno del Analyst.

---

## Metadata

| Campo | Valor |
|-------|-------|
| **Proyecto** | `[nombre-del-proyecto]` |
| **Feature ID** | `FEAT-XXX` |
| **Fecha de Discovery** | `YYYY-MM-DD` |
| **Estado** | `Activo / Completado` |
| **Analista** | `[nombre]` |

---

## 1. Descripción de la Idea

> Descripción breve de la idea tal como fue presentada por el stakeholder. Sin interpretar, sin reformular. Capturar la intención original.

```
[Transcripción o paráfrasis fiel de la idea original]
```

---

## 2. Contexto Consumido

> Documentos y fuentes consultados por el Analyst antes de iniciar el discovery. El objetivo es evitar preguntar algo cuya respuesta ya existe en el sistema.

- [ ] `.ai/context.md` — Leído
- [ ] `.ai/business-rules.md` — Leído
- [ ] `.ai/architecture.md` — Leído
- [ ] `.ai/glossary.md` — Leído
- [ ] `features/FEAT-XXX-relacionadas/` — Consultadas si existen
- [ ] Skills activas en el entorno — Consultadas

**Conocimiento previo relevante encontrado:**

```
[Qué información del contexto del proyecto ya responde parte de la idea]
[Reglas de negocio existentes que aplican]
[Decisiones arquitectónicas previas que impactan]
```

---

## 3. Ambigüedades Detectadas

> Lista de ambigüedades que impiden producir una spec completa. Solo las críticas — no preguntar lo que puede inferirse del contexto.

| ID | Ambigüedad | Criticidad | Impacto si no se resuelve |
|----|-----------|------------|--------------------------|
| AM-01 | `[descripción clara de la ambigüedad]` | Blocker / Alta / Media | `[qué asume el Analyst si no hay respuesta]` |
| AM-02 | | | |

---

## 4. Sesión de Discovery

> Registro de la conversación de discovery. Para cada ambigüedad, el Analyst propone alternativas con contexto — no hace preguntas abiertas.

---

### AM-01: [Título de la ambigüedad]

**Contexto:**  
> [Por qué esta ambigüedad existe y qué la hace crítica]

**Opciones evaluadas:**

**A) [Nombre de la opción]**  
[Descripción clara de la opción]  
*Cuándo elegirla:* [contexto en que tiene sentido]  
*Trade-offs:* [qué se gana, qué se sacrifica]

**B) [Nombre de la opción]**  
[Descripción clara de la opción]  
*Cuándo elegirla:* [contexto en que tiene sentido]  
*Trade-offs:* [qué se gana, qué se sacrifica]

**C) [Nombre de la opción]** *(si existe una tercera vía relevante)*  
[Descripción clara de la opción]  
*Cuándo elegirla:* [contexto en que tiene sentido]  
*Trade-offs:* [qué se gana, qué se sacrifica]

**Decisión tomada:** `[A / B / C / Pendiente]`  
**Justificación:** `[por qué se eligió esta opción]`  
**Respondida por:** `[stakeholder / inferida del contexto / asumida con riesgo]`

---

### AM-02: [Título de la ambigüedad]

*(Repetir estructura para cada ambigüedad)*

---

## 5. Decisiones del Discovery

> Resumen ejecutivo de todas las decisiones tomadas durante el discovery. Es la fuente que el Analyst usa para escribir la `spec.md`.

| ID | Ambigüedad | Decisión | Fuente |
|----|-----------|---------|--------|
| AM-01 | `[ambigüedad]` | `[decisión tomada]` | Stakeholder / Contexto / Asumida |
| AM-02 | | | |

---

## 6. Alternativas Descartadas

> Registro de opciones evaluadas y rechazadas. Permite entender el razonamiento sin necesidad de repetir el análisis en el futuro.

| Alternativa | Motivo del descarte |
|-------------|---------------------|
| `[opción descartada]` | `[por qué no se eligió]` |

---

## 7. Riesgos Funcionales Identificados

> Riesgos detectados durante el discovery que deben ser atendidos en la `spec.md` o en la `architecture.md`.

| ID | Riesgo | Criticidad | Acción recomendada |
|----|--------|------------|-------------------|
| RF-01 | `[descripción]` | Alta / Media / Baja | `[qué hacer]` |

---

## 8. Preguntas Abiertas Residuales

> Ambigüedades que no pudieron resolverse durante el discovery y que el Analyst documenta como preguntas abiertas en `spec.md`.

| ID | Pregunta | Criticidad | Responsable |
|----|---------|------------|-------------|
| PA-01 | `[pregunta que no pudo responderse]` | Blocker / Alta / Media | `[stakeholder / tech lead]` |

---

## Estado del Discovery

```
[ ] Discovery iniciado
[ ] Todas las ambigüedades críticas resueltas o documentadas como PA en spec.md
[ ] spec.md producida a partir de este discovery
[ ] Estado del discovery: COMPLETADO
```

---

*Discovery template v1.0 — ai-agents framework | github.com/ezequielmendoza-dev/abbia-os*
