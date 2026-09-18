import React from 'react';
import { Box, Text } from 'ink';
import { colors, chalkTheme } from '../theme.js';
import { ProjectInfo } from '../utils/abbia.js';

interface HeaderProps {
  projectInfo: ProjectInfo;
  currentScreen?: string;
}

export const Header: React.FC<HeaderProps> = ({ projectInfo, currentScreen }) => {
  const activeCount = projectInfo.initiatives.length;
  const approvedCount = projectInfo.initiatives.filter((i) => i.qaVerdict === 'APROBADO').length;

  return (
    <Box flexDirection="column" marginBottom={1}>
      {/* Brand Header */}
      <Box
        borderStyle="round"
        borderColor={colors.primary}
        paddingX={2}
        paddingY={0}
        flexDirection="row"
        justifyContent="space-between"
      >
        <Box flexDirection="row" alignItems="center">
          {/* Prisma Delta Logo (Parallel Lines) */}
          <Box flexDirection="column" marginRight={2}>
            <Text color={colors.primary}>     ▲</Text>
            <Text color={colors.primary}>    ╱ ╲</Text>
            <Text color={colors.primary}>   ╱╱ ╲╲</Text>
            <Text color={colors.primary}>  ╱╱   ╲╲</Text>
            <Text>
              <Text color={colors.secondary}> ●</Text>
              <Text color={colors.secondary}>═══</Text>
              <Text color={colors.accent}>◆</Text>
              <Text color={colors.secondary}>═══</Text>
              <Text color={colors.secondary}>●</Text>
            </Text>
            <Text color={colors.primary}>╱╱       ╲╲</Text>
            <Text color={colors.secondary}>●═══════════●</Text>
          </Box>

          <Box flexDirection="column" justifyContent="center">
            <Box flexDirection="row" alignItems="center">
              <Text color={colors.primary} bold>
                ABBIA OS
              </Text>
              <Text color={colors.textDim}> │ </Text>
              <Text color={colors.secondary} bold>
                v4.0.0
              </Text>
            </Box>
            <Text color={colors.textDim}>AI Software Engineering Operating System</Text>
            <Text color={colors.textMuted} italic>
              "Layered Context, Structured Memory, Autonomous Delivery"
            </Text>
          </Box>
        </Box>

        <Box flexDirection="column" alignItems="flex-end" justifyContent="center">
          <Box flexDirection="row">
            <Text color={colors.textDim}>Project: </Text>
            <Text color={colors.text} bold>
              {projectInfo.projectName}
            </Text>
          </Box>
          <Box flexDirection="row">
            <Text color={colors.textDim}>Branch: </Text>
            <Text color={colors.accent}>{projectInfo.gitBranch}</Text>
          </Box>
        </Box>
      </Box>

      {/* Status Bar */}
      <Box
        flexDirection="row"
        justifyContent="space-between"
        paddingX={1}
      >
        <Box flexDirection="row" gap={2}>
          <Text>
            <Text color={colors.textDim}>Iniciativas Activas: </Text>
            <Text color={activeCount > 0 ? colors.warning : colors.textMuted} bold>
              {activeCount}
            </Text>
          </Text>
          <Text>
            <Text color={colors.textDim}>Listas para Archivo: </Text>
            <Text color={approvedCount > 0 ? colors.secondary : colors.textMuted} bold>
              {approvedCount}
            </Text>
          </Text>
          <Text>
            <Text color={colors.textDim}>Histórico Archivado: </Text>
            <Text color={colors.textMuted}>{projectInfo.archivedCount}</Text>
          </Text>
        </Box>

        {currentScreen && (
          <Box>
            <Text color={colors.primaryDark}>[ {currentScreen} ]</Text>
          </Box>
        )}
      </Box>
    </Box>
  );
};
