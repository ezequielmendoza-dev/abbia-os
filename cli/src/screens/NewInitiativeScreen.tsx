import React, { useState } from 'react';
import { Box, Text } from 'ink';
import SelectInput from 'ink-select-input';
import TextInput from 'ink-text-input';
import { colors } from '../theme.js';

interface NewInitiativeScreenProps {
  onCancel: () => void;
  onSubmit: (type: string, id: string, slug: string) => void;
}

export const NewInitiativeScreen: React.FC<NewInitiativeScreenProps> = ({
  onCancel,
  onSubmit,
}) => {
  const [step, setStep] = useState<'type' | 'id' | 'slug' | 'confirm'>('type');
  const [selectedType, setSelectedType] = useState<string>('feature');
  const [initiativeId, setInitiativeId] = useState<string>('');
  const [initiativeSlug, setInitiativeSlug] = useState<string>('');
  const [error, setError] = useState<string>('');

  const typeOptions = [
    { label: '✨ Feature (Nueva funcionalidad)', value: 'feature' },
    { label: '🐛 Bug (Corrección de error)', value: 'bug' },
    { label: '🔍 Audit (Auditoría de seguridad / arquitectura)', value: 'audit' },
    { label: '♻️  Refactor (Mejora estructural)', value: 'refactor' },
  ];

  const handleIdSubmit = () => {
    const trimmed = initiativeId.trim();
    if (!trimmed) {
      setError('El ID no puede estar vacío (ej: 01, 102, auth)');
      return;
    }
    setError('');
    setStep('slug');
  };

  const handleSlugSubmit = () => {
    const trimmed = initiativeSlug.trim();
    if (!trimmed) {
      setError('El slug no puede estar vacío (ej: login-with-google)');
      return;
    }
    const cleanSlug = trimmed.toLowerCase().replace(/[^a-z0-9-]/g, '-');
    setInitiativeSlug(cleanSlug);
    setError('');
    setStep('confirm');
  };

  const confirmOptions = [
    { label: '🚀 Sí, crear iniciativa', value: 'yes' },
    { label: '❌ Cancelar y volver', value: 'no' },
  ];

  return (
    <Box flexDirection="column" borderStyle="round" borderColor={colors.primary} padding={1}>
      <Box marginBottom={1} flexDirection="row" justifyContent="space-between">
        <Text color={colors.primary} bold>
          🚀 Nueva Iniciativa SDD
        </Text>
        <Text color={colors.textDim}>[ Esc / Ctrl+C para cancelar ]</Text>
      </Box>

      {/* Step 1: Select Type */}
      {step === 'type' && (
        <Box flexDirection="column">
          <Text color={colors.textMuted} marginBottom={1}>
            Paso 1/3: Selecciona el tipo de iniciativa:
          </Text>
          <SelectInput
            items={typeOptions}
            onSelect={(item) => {
              setSelectedType(item.value);
              setStep('id');
            }}
          />
        </Box>
      )}

      {/* Step 2: Input ID */}
      {step === 'id' && (
        <Box flexDirection="column">
          <Text color={colors.textMuted} marginBottom={1}>
            Paso 2/3: Ingresa el identificador numérico o clave (ej: 01, 105, auth):
          </Text>
          <Box borderStyle="single" borderColor={colors.primary} paddingX={1}>
            <Text color={colors.primary}>ID: </Text>
            <TextInput
              value={initiativeId}
              onChange={setInitiativeId}
              onSubmit={handleIdSubmit}
              placeholder="01"
            />
          </Box>
          {error && <Text color={colors.error}>{error}</Text>}
          <Box marginTop={1}>
            <Text color={colors.textDim}>Presiona Enter para continuar</Text>
          </Box>
        </Box>
      )}

      {/* Step 3: Input Slug */}
      {step === 'slug' && (
        <Box flexDirection="column">
          <Text color={colors.textMuted} marginBottom={1}>
            Paso 3/3: Ingresa el slug descriptivo en minúsculas (ej: user-authentication):
          </Text>
          <Box borderStyle="single" borderColor={colors.primary} paddingX={1}>
            <Text color={colors.primary}>Slug: </Text>
            <TextInput
              value={initiativeSlug}
              onChange={setInitiativeSlug}
              onSubmit={handleSlugSubmit}
              placeholder="user-authentication"
            />
          </Box>
          {error && <Text color={colors.error}>{error}</Text>}
          <Box marginTop={1}>
            <Text color={colors.textDim}>Presiona Enter para continuar</Text>
          </Box>
        </Box>
      )}

      {/* Step 4: Confirmation */}
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
              Resumen de la nueva iniciativa:
            </Text>
            <Text>
              <Text color={colors.textDim}>Directorio: </Text>
              <Text color={colors.primary} bold>
                .abbia/initiatives/{selectedType}-{initiativeId}-{initiativeSlug}/
              </Text>
            </Text>
            <Text>
              <Text color={colors.textDim}>Tipo: </Text>
              <Text color={colors.text}>{selectedType}</Text>
            </Text>
          </Box>

          <SelectInput
            items={confirmOptions}
            onSelect={(item) => {
              if (item.value === 'yes') {
                onSubmit(selectedType, initiativeId, initiativeSlug);
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
