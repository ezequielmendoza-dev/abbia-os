import React from 'react';
import { Box, Text } from 'ink';
import { colors } from '../theme.js';
import { InitiativeInfo } from '../utils/abbia.js';

interface InitiativeCardProps {
  initiative: InitiativeInfo;
  isSelected?: boolean;
}

export const InitiativeCard: React.FC<InitiativeCardProps> = ({ initiative, isSelected }) => {
  const phaseBadge = (num: string, name: string, done: boolean) => {
    return (
      <Text color={done ? colors.secondary : colors.textDim}>
        [{num}:{name} {done ? '✓' : '·'}]
      </Text>
    );
  };

  const getQaBadge = () => {
    if (!initiative.hasQa) {
      return <Text color={colors.textDim}>[6:qa ·]</Text>;
    }
    if (initiative.qaVerdict === 'APROBADO') {
      return (
        <Text color={colors.secondary} bold>
          [6:qa APROBADO ✓]
        </Text>
      );
    }
    if (initiative.qaVerdict === 'APROBADO_CON_OBSERVACIONES') {
      return (
        <Text color={colors.warning} bold>
          [6:qa OBS ⚠]
        </Text>
      );
    }
    if (initiative.qaVerdict === 'RECHAZADO') {
      return (
        <Text color={colors.error} bold>
          [6:qa RECHAZADO ✗]
        </Text>
      );
    }
    return <Text color={colors.warning}>[6:qa EN CURSO]</Text>;
  };

  return (
    <Box
      flexDirection="column"
      borderStyle={isSelected ? 'double' : 'single'}
      borderColor={isSelected ? colors.primary : colors.border}
      paddingX={1}
      marginBottom={1}
    >
      <Box flexDirection="row" justifyContent="space-between">
        <Text color={isSelected ? colors.primary : colors.text} bold>
          {isSelected ? '▶ ' : '  '}📁 {initiative.folderName}
        </Text>
        {initiative.isReadyToArchive && (
          <Text color={colors.secondary} bold>
            READY TO ARCHIVE 📦
          </Text>
        )}
      </Box>

      <Box flexDirection="row" gap={1} marginTop={0}>
        {phaseBadge('1', 'spec', initiative.hasSpec)}
        {phaseBadge('2', 'arch', initiative.hasArch)}
        {phaseBadge('3', 'plan', initiative.hasPlan)}
        {phaseBadge('4', 'test', initiative.hasTest)}
        {phaseBadge('5', 'dev', initiative.hasDev)}
        {getQaBadge()}
      </Box>
    </Box>
  );
};
