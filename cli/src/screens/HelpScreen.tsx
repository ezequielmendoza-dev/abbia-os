import React from 'react';
import { Box, Text, useInput } from 'ink';
import { colors } from '../theme.js';

interface HelpScreenProps {
  onBack: () => void;
}

export const HelpScreen: React.FC<HelpScreenProps> = ({ onBack }) => {
  useInput((input, key) => {
    if (key.return || key.escape || input === 'q' || input === ' ') {
      onBack();
    }
  });

  return (
    <Box flexDirection="column" borderStyle="round" borderColor={colors.primary} padding={1}>
      <Box marginBottom={1} flexDirection="row" justifyContent="space-between">
        <Text color={colors.primary} bold>
          Abbia OS v4.0.0 — Guía Rápida & SDD Framework
        </Text>
        <Text color={colors.textDim}>[ Enter / Esc / q para volver ]</Text>
      </Box>

      {/* 3-Tier Memory */}
      <Box flexDirection="column" marginBottom={1}>
        <Text color={colors.secondary} bold>
          🧠 Arquitectura de Memoria Persistente en 3 Capas (3-Tier Memory):
        </Text>
        <Text color={colors.text}>
          • <Text bold>Tier 1 (Sistema):</Text> .abbia/memory/ (context-snapshot.md, workflow-log.md)
        </Text>
        <Text color={colors.text}>
          • <Text bold>Tier 2 (Iniciativas):</Text> .abbia/initiatives/ (1-spec → 2-arch → 3-plan → 4-test → 5-dev → 6-qa)
        </Text>
        <Text color={colors.text}>
          • <Text bold>Tier 3 (Grafo de Decisiones):</Text> .abbia/knowledge-graph.yaml y ADRs
        </Text>
      </Box>

      {/* Reglas R1-R6 */}
      <Box flexDirection="column" marginBottom={1}>
        <Text color={colors.accent} bold>
          📋 Reglas de Contribución & Ejecución (R1 - R6):
        </Text>
        <Text color={colors.textMuted}>
          • <Text bold>R1/R2/R3:</Text> Reutilizar y actualizar documentos existentes. Evitar duplicar versiones (-v2).
        </Text>
        <Text color={colors.textMuted}>
          • <Text bold>R4:</Text> Todo cambio estructural se documenta en CHANGELOG.md.
        </Text>
        <Text color={colors.textMuted}>
          • <Text bold>R5:</Text> La documentación refleja el estado actual del sistema.
        </Text>
        <Text color={colors.warning} bold>
          • R6 (Mandatorio): Cierre de fase y registro de telemetría con finish-phase.sh antes de finalizar el turno.
        </Text>
      </Box>

      {/* 6 Roles */}
      <Box flexDirection="column" marginBottom={1}>
        <Text color={colors.primary} bold>
          👥 6 Roles Especializados:
        </Text>
        <Text color={colors.textDim}>
          Analyst (Spec) → Architect (Diseño/ADR) → Tech Lead (Plan) → Developer (Código) → QA (Adversarial) → DevOps (CI/CD)
        </Text>
      </Box>

      <Box marginTop={1} justifyContent="center">
        <Text color={colors.primary} bold>
          [ Presiona Enter o Esc para volver al menú principal ]
        </Text>
      </Box>
    </Box>
  );
};
