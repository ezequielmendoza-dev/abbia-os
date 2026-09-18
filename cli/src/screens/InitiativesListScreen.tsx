import React, { useState } from 'react';
import { Box, Text, useInput } from 'ink';
import { colors } from '../theme.js';
import { ProjectInfo } from '../utils/abbia.js';
import { InitiativeCard } from '../components/InitiativeCard.js';

interface InitiativesListScreenProps {
  projectInfo: ProjectInfo;
  onBack: () => void;
}

export const InitiativesListScreen: React.FC<InitiativesListScreenProps> = ({
  projectInfo,
  onBack,
}) => {
  const [selectedIndex, setSelectedIndex] = useState(0);

  useInput((input, key) => {
    if (key.escape || input === 'q' || key.return) {
      onBack();
      return;
    }
    if (key.upArrow) {
      setSelectedIndex((prev) => (prev > 0 ? prev - 1 : projectInfo.initiatives.length - 1));
    }
    if (key.downArrow) {
      setSelectedIndex((prev) => (prev < projectInfo.initiatives.length - 1 ? prev + 1 : 0));
    }
  });

  return (
    <Box flexDirection="column" borderStyle="round" borderColor={colors.primary} padding={1}>
      <Box marginBottom={1} flexDirection="row" justifyContent="space-between">
        <Text color={colors.primary} bold>
          📋 Iniciativas Activas en .abbia/initiatives/ ({projectInfo.initiatives.length})
        </Text>
        <Text color={colors.textDim}>[ ↑/↓ Navegar  │  Enter/Esc/q Volver ]</Text>
      </Box>

      {projectInfo.initiatives.length === 0 ? (
        <Box paddingY={1}>
          <Text color={colors.textMuted}>No hay iniciativas activas registradas.</Text>
        </Box>
      ) : (
        <Box flexDirection="column">
          {projectInfo.initiatives.map((init, index) => (
            <InitiativeCard
              key={init.id}
              initiative={init}
              isSelected={index === selectedIndex}
            />
          ))}
        </Box>
      )}

      <Box marginTop={1} justifyContent="center">
        <Text color={colors.primary} bold>
          [ Presiona Enter o Esc para volver al menú principal ]
        </Text>
      </Box>
    </Box>
  );
};
