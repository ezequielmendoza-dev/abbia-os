import React, { useState } from 'react';
import { Box, Text, useInput } from 'ink';
import SelectInput from 'ink-select-input';
import { colors } from '../theme.js';
import { ProjectInfo } from '../utils/abbia.js';

interface MenuItem {
  label: string;
  value: string;
  description: string;
  badge?: string;
}

interface MainMenuProps {
  projectInfo: ProjectInfo;
  onSelect: (value: string) => void;
}

export const MainMenu: React.FC<MainMenuProps> = ({ projectInfo, onSelect }) => {
  const [selectedDesc, setSelectedDesc] = useState<string>(
    'Crea una nueva feature, bug, auditoría o refactor con la estructura SDD estandarizada.'
  );

  useInput((input, key) => {
    if (key.escape || input === 'q') {
      onSelect('exit');
    }
  });

  const items: MenuItem[] = [
    {
      label: '🚀  Nueva Iniciativa (Wizard)',
      value: 'new',
      description: 'Crea una nueva feature, bug, auditoría o refactor con la estructura SDD estandarizada.',
    },
    {
      label: `📋  Ver Iniciativas y Fases (${projectInfo.initiatives.length})`,
      value: 'list',
      description: 'Inspecciona el avance de las 6 fases (spec, arch, plan, test, dev, qa) de cada iniciativa.',
    },
    {
      label: '🏁  Cerrar Fase y Telemetría (finish-phase)',
      value: 'finish',
      description: 'Ejecuta el cierre mandatorio (R6): registra tokens, modelo, duración y snapshot de memoria.',
    },
    {
      label: '📦  Archivar Iniciativa Aprobada',
      value: 'archive',
      description: 'Mueve iniciativas con QA Aprobado a .abbia/archive/ preservando trazabilidad histórica.',
    },
    {
      label: '🔄  Sincronizar y Reparar (.abbia/initiatives)',
      value: 'sync',
      description: 'Normaliza iniciativas huérfanas, repara numeraciones y sincroniza el registro general.',
    },
    {
      label: '🩺  Validar Salud del Proyecto',
      value: 'validate',
      description: 'Audita el cumplimiento de la estructura Abbia OS, 3-Tier Memory, KG y scripts.',
    },
    {
      label: '📊  Abrir Dashboard HTML Interactivo',
      value: 'dashboard',
      description: 'Genera y abre en tu navegador el dashboard visual con métricas, gráficos y DAG.',
    },
    {
      label: '⬆️   Actualizar Abbia OS',
      value: 'update',
      description: 'Actualiza el submódulo Abbia OS a la última versión disponible en GitHub.',
    },
    {
      label: '❓  Guía del Framework y SDD',
      value: 'help',
      description: 'Consulta los 6 roles, las reglas R1-R6, el ciclo SDD y la memoria en 3 capas.',
    },
    {
      label: '🚪  Salir',
      value: 'exit',
      description: 'Cierra el CLI interactivo de Abbia OS.',
    },
  ];

  return (
    <Box flexDirection="column">
      <Box
        flexDirection="column"
        borderStyle="single"
        borderColor={colors.border}
        paddingX={1}
        paddingY={0}
      >
        <SelectInput
          items={items}
          onSelect={(item) => onSelect(item.value)}
          onHighlight={(item) => {
            const match = items.find((i) => i.value === item.value);
            if (match) setSelectedDesc(match.description);
          }}
          indicatorComponent={({ isSelected }) => (
            <Text color={isSelected ? colors.primary : colors.textDim}>
              {isSelected ? '▶ ' : '  '}
            </Text>
          )}
          itemComponent={({ isSelected, label }) => (
            <Text color={isSelected ? colors.primary : colors.text} bold={isSelected}>
              {label}
            </Text>
          )}
        />
      </Box>

      {/* Description / Helper Box */}
      <Box
        marginTop={1}
        borderStyle="round"
        borderColor={colors.cardBg}
        paddingX={2}
        paddingY={0}
      >
        <Text color={colors.textMuted} italic>
          💡 {selectedDesc}
        </Text>
      </Box>

      {/* Keyboard Shortcuts Hint */}
      <Box marginTop={1} paddingX={1} justifyContent="center">
        <Text color={colors.textDim}>
          [ ↑ / ↓ ] Navegar   [ Enter ] Seleccionar   [ q / Esc ] Salir
        </Text>
      </Box>
    </Box>
  );
};
