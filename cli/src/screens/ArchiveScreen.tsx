import React, { useState } from 'react';
import { Box, Text } from 'ink';
import SelectInput from 'ink-select-input';
import { colors } from '../theme.js';
import { ProjectInfo } from '../utils/abbia.js';

interface ArchiveScreenProps {
  projectInfo: ProjectInfo;
  onCancel: () => void;
  onSubmit: (initiativeName: string) => void;
}

export const ArchiveScreen: React.FC<ArchiveScreenProps> = ({
  projectInfo,
  onCancel,
  onSubmit,
}) => {
  const [selectedInit, setSelectedInit] = useState<string>('');
  const [isConfirming, setIsConfirming] = useState<boolean>(false);

  if (projectInfo.initiatives.length === 0) {
    return (
      <Box flexDirection="column" borderStyle="round" borderColor={colors.warning} padding={1}>
        <Text color={colors.warning} bold>
          ⚠️  No hay iniciativas activas para archivar.
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

  const items = projectInfo.initiatives.map((init) => {
    let tag = '';
    if (init.qaVerdict === 'APROBADO') {
      tag = ' [🟢 QA APROBADO - LISTO]';
    } else if (init.qaVerdict === 'APROBADO_CON_OBSERVACIONES') {
      tag = ' [🟡 OBS]';
    } else {
      tag = ' [⏳ EN PROGRESO / PENDIENTE]';
    }
    return {
      label: `📁 ${init.folderName}${tag}`,
      value: init.folderName,
    };
  });

  return (
    <Box flexDirection="column" borderStyle="round" borderColor={colors.primary} padding={1}>
      <Box marginBottom={1} flexDirection="row" justifyContent="space-between">
        <Text color={colors.primary} bold>
          📦 Archivar Iniciativa (.abbia/archive/)
        </Text>
        <Text color={colors.textDim}>[ Esc / Ctrl+C para cancelar ]</Text>
      </Box>

      {!isConfirming ? (
        <Box flexDirection="column">
          <Text color={colors.textMuted} marginBottom={1}>
            Selecciona la iniciativa a mover al archivo histórico:
          </Text>
          <SelectInput
            items={items}
            onSelect={(item) => {
              setSelectedInit(item.value);
              setIsConfirming(true);
            }}
          />
        </Box>
      ) : (
        <Box flexDirection="column">
          <Box
            borderStyle="single"
            borderColor={colors.warning}
            padding={1}
            flexDirection="column"
            marginBottom={1}
          >
            <Text color={colors.warning} bold>
              ¿Confirmas archivar la iniciativa?
            </Text>
            <Text color={colors.text}>
              Se moverá a <Text color={colors.primary}>.abbia/archive/{selectedInit}/</Text>
            </Text>
          </Box>

          <SelectInput
            items={[
              { label: '📦 Sí, archivar iniciativa', value: 'yes' },
              { label: '❌ Cancelar', value: 'no' },
            ]}
            onSelect={(item) => {
              if (item.value === 'yes') {
                onSubmit(selectedInit);
              } else {
                setIsConfirming(false);
              }
            }}
          />
        </Box>
      )}
    </Box>
  );
};
