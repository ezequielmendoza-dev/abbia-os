import React, { useState } from 'react';
import { Box, Text, useInput } from 'ink';
import SelectInput from 'ink-select-input';
import { colors } from '../theme.js';
import { ProjectInfo } from '../utils/abbia.js';

interface FinishPhaseScreenProps {
  projectInfo: ProjectInfo;
  onCancel: () => void;
  onSubmit: (args: string[]) => void;
}

export const FinishPhaseScreen: React.FC<FinishPhaseScreenProps> = ({
  projectInfo,
  onCancel,
  onSubmit,
}) => {
  const [step, setStep] = useState<'initiative' | 'phase' | 'role' | 'model' | 'confirm'>('initiative');
  const [selectedInit, setSelectedInit] = useState<string>('');
  const [selectedPhase, setSelectedPhase] = useState<string>('5-dev');
  const [selectedRole, setSelectedRole] = useState<string>('developer');
  const [selectedModel, setSelectedModel] = useState<string>('claude-3-7-sonnet');
  const [tokensIn, setTokensIn] = useState<string>('5000');
  const [tokensOut, setTokensOut] = useState<string>('1500');
  const [duration, setDuration] = useState<string>('60');

  useInput((input, key) => {
    if (key.escape) {
      if (step === 'initiative') {
        onCancel();
      } else if (step === 'phase') {
        setStep('initiative');
      } else if (step === 'role') {
        setStep('phase');
      } else if (step === 'model') {
        setStep('role');
      } else if (step === 'confirm') {
        setStep('model');
      }
    }
  });

  if (projectInfo.initiatives.length === 0) {
    return (
      <Box flexDirection="column" borderStyle="round" borderColor={colors.warning} padding={1}>
        <Text color={colors.warning} bold>
          ⚠️  No hay iniciativas activas en .abbia/initiatives/
        </Text>
        <Text color={colors.textMuted} marginTop={1}>
          Crea una nueva iniciativa primero con la opción "Nueva Iniciativa".
        </Text>
        <Box marginTop={1}>
          <SelectInput
            items={[{ label: 'Volver al Menú Principal', value: 'back' }]}
            onSelect={onCancel}
          />
        </Box>
      </Box>
    );
  }

  const initItems = [
    ...projectInfo.initiatives.map((init) => ({
      label: `📁 ${init.folderName} (QA: ${init.qaVerdict || 'PENDIENTE'})`,
      value: init.folderName,
    })),
    { label: '↩️  Cancelar y volver al menú', value: '__cancel__' },
  ];

  const phaseItems = [
    { label: '1️⃣  Fase 1: Especificación Funcional (1-spec.md)', value: '1-spec' },
    { label: '2️⃣  Fase 2: Arquitectura Técnica (2-arch.md)', value: '2-arch' },
    { label: '3️⃣  Fase 3: Plan de Implementación (3-plan.md)', value: '3-plan' },
    { label: '4️⃣  Fase 4: Estrategia de Pruebas (4-test.md)', value: '4-test' },
    { label: '5️⃣  Fase 5: Desarrollo de Código (5-dev.md)', value: '5-dev' },
    { label: '6️⃣  Fase 6: Validación Adversarial de QA (6-qa.md)', value: '6-qa' },
    { label: '↩️  Volver al paso anterior', value: '__back__' },
  ];

  const roleItems = [
    { label: '👩‍💻 Senior Developer (developer)', value: 'developer' },
    { label: '🕵️ QA Engineer (qa)', value: 'qa' },
    { label: '📐 Software Architect (architect)', value: 'architect' },
    { label: '📋 Product Analyst (analyst)', value: 'analyst' },
    { label: '🎨 UI Designer (ui-designer)', value: 'ui-designer' },
    { label: '👑 Tech Lead (tech-lead)', value: 'tech-lead' },
    { label: '🚀 DevOps Engineer (devops)', value: 'devops' },
    { label: '🧠 Skill Manager (skill-manager)', value: 'skill-manager' },
    { label: '↩️  Volver al paso anterior', value: '__back__' },
  ];

  const modelItems = [
    { label: 'Claude 3.7 Sonnet (claude-3-7-sonnet)', value: 'claude-3-7-sonnet' },
    { label: 'Gemini 2.5 Pro (gemini-2.5-pro)', value: 'gemini-2.5-pro' },
    { label: 'Gemini 2.5 Flash (gemini-2.5-flash)', value: 'gemini-2.5-flash' },
    { label: 'GPT-4o (gpt-4o)', value: 'gpt-4o' },
    { label: 'o3-mini (o3-mini)', value: 'o3-mini' },
    { label: 'Otro / Modelo Custom (custom)', value: 'custom-model' },
    { label: '↩️  Volver al paso anterior', value: '__back__' },
  ];

  const handleFinish = () => {
    const args = [
      selectedInit,
      selectedPhase,
      selectedRole,
      '--model',
      selectedModel,
      '--tokens-in',
      tokensIn || '0',
      '--tokens-out',
      tokensOut || '0',
      '--duration',
      duration || '0',
      '--source',
      'estimate',
    ];
    onSubmit(args);
  };

  return (
    <Box flexDirection="column" borderStyle="round" borderColor={colors.primary} padding={1}>
      <Box marginBottom={1} flexDirection="row" justifyContent="space-between">
        <Text color={colors.primary} bold>
          🏁 Cierre Mandatorio de Fase (finish-phase — Regla R6)
        </Text>
        <Text color={colors.textDim}>[ Esc: Volver / Cancelar ]</Text>
      </Box>

      {/* Step 1: Select Initiative */}
      {step === 'initiative' && (
        <Box flexDirection="column">
          <Text color={colors.textMuted} marginBottom={1}>
            Paso 1/4: Selecciona la iniciativa a cerrar:
          </Text>
          <SelectInput
            items={initItems}
            onSelect={(item) => {
              if (item.value === '__cancel__') {
                onCancel();
              } else {
                setSelectedInit(item.value);
                setStep('phase');
              }
            }}
          />
        </Box>
      )}

      {/* Step 2: Select Phase */}
      {step === 'phase' && (
        <Box flexDirection="column">
          <Text color={colors.textMuted} marginBottom={1}>
            Iniciativa: <Text color={colors.primary} bold>{selectedInit}</Text>
          </Text>
          <Text color={colors.textMuted} marginBottom={1}>
            Paso 2/4: Selecciona la fase completada:
          </Text>
          <SelectInput
            items={phaseItems}
            onSelect={(item) => {
              if (item.value === '__back__') {
                setStep('initiative');
              } else {
                setSelectedPhase(item.value);
                setStep('role');
              }
            }}
          />
        </Box>
      )}

      {/* Step 3: Select Role */}
      {step === 'role' && (
        <Box flexDirection="column">
          <Text color={colors.textMuted} marginBottom={1}>
            Paso 3/4: Selecciona el rol del agente responsable:
          </Text>
          <SelectInput
            items={roleItems}
            onSelect={(item) => {
              if (item.value === '__back__') {
                setStep('phase');
              } else {
                setSelectedRole(item.value);
                setStep('model');
              }
            }}
          />
        </Box>
      )}

      {/* Step 4: Select Model */}
      {step === 'model' && (
        <Box flexDirection="column">
          <Text color={colors.textMuted} marginBottom={1}>
            Paso 4/4: Modelo LLM utilizado en esta fase:
          </Text>
          <SelectInput
            items={modelItems}
            onSelect={(item) => {
              if (item.value === '__back__') {
                setStep('role');
              } else {
                setSelectedModel(item.value);
                setStep('confirm');
              }
            }}
          />
        </Box>
      )}

      {/* Step 5: Confirmation */}
      {step === 'confirm' && (
        <Box flexDirection="column">
          <Box
            borderStyle="single"
            borderColor={colors.secondary}
            padding={1}
            flexDirection="column"
            marginBottom={1}
          >
            <Text color={colors.secondary} bold>
              Resumen del Cierre de Fase:
            </Text>
            <Text>
              <Text color={colors.textDim}>Iniciativa: </Text>
              <Text color={colors.primary} bold>{selectedInit}</Text>
            </Text>
            <Text>
              <Text color={colors.textDim}>Fase: </Text>
              <Text color={colors.text} bold>{selectedPhase}</Text>
            </Text>
            <Text>
              <Text color={colors.textDim}>Rol: </Text>
              <Text color={colors.text}>{selectedRole}</Text>
            </Text>
            <Text>
              <Text color={colors.textDim}>Modelo: </Text>
              <Text color={colors.accent}>{selectedModel}</Text>
            </Text>
          </Box>

          <SelectInput
            items={[
              { label: '🏁 Confirmar y Registrar Telemetría', value: 'yes' },
              { label: '↩️  Volver al paso anterior', value: 'back' },
              { label: '❌ Cancelar y volver al menú', value: 'cancel' },
            ]}
            onSelect={(item) => {
              if (item.value === 'yes') {
                handleFinish();
              } else if (item.value === 'back') {
                setStep('model');
              } else {
                onCancel();
              }
            }}
          />
        </Box>
      )}
    </Box>
  );
};
