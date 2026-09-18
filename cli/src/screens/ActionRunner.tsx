import React, { useState, useEffect } from 'react';
import { Box, Text, useInput } from 'ink';
import Spinner from 'ink-spinner';
import { colors } from '../theme.js';
import { executeAbbiaScript } from '../utils/abbia.js';

interface ActionRunnerProps {
  title: string;
  scriptName: string;
  args: string[];
  projectRoot: string;
  onDone: () => void;
}

export const ActionRunner: React.FC<ActionRunnerProps> = ({
  title,
  scriptName,
  args,
  projectRoot,
  onDone,
}) => {
  const [output, setOutput] = useState<string[]>([]);
  const [isRunning, setIsRunning] = useState(true);
  const [exitCode, setExitCode] = useState<number | null>(null);

  useEffect(() => {
    const proc = executeAbbiaScript(
      scriptName,
      args,
      projectRoot,
      (chunk) => {
        setOutput((prev) => [...prev, chunk]);
      },
      (code) => {
        setIsRunning(false);
        setExitCode(code);
      }
    );

    return () => {
      if (proc) {
        try {
          proc.kill();
        } catch {}
      }
    };
  }, []);

  useInput((input, key) => {
    if (!isRunning) {
      if (key.return || key.escape || input === 'q' || input === ' ') {
        onDone();
      }
    }
  });

  // Keep last 15 lines for clear display
  const rawText = output.join('');
  const lines = rawText.split('\n');
  const visibleLines = lines.slice(-15);

  return (
    <Box flexDirection="column" borderStyle="round" borderColor={colors.primary} padding={1}>
      <Box flexDirection="row" justifyContent="space-between" marginBottom={1}>
        <Box flexDirection="row" alignItems="center">
          {isRunning ? (
            <Text color={colors.primary}>
              <Spinner type="dots" /> <Text bold>Ejecutando: {title}</Text>
            </Text>
          ) : exitCode === 0 ? (
            <Text color={colors.secondary} bold>
              ✓ Completado con éxito: {title}
            </Text>
          ) : (
            <Text color={colors.error} bold>
              ✗ Error al ejecutar (Exit code: {exitCode}): {title}
            </Text>
          )}
        </Box>
        <Text color={colors.textDim}>
          bash {scriptName} {args.join(' ')}
        </Text>
      </Box>

      {/* Output Console Box */}
      <Box
        flexDirection="column"
        borderStyle="single"
        borderColor={colors.border}
        paddingX={1}
        paddingY={0}
        minHeight={8}
      >
        {visibleLines.length === 0 ? (
          <Text color={colors.textDim}>Iniciando proceso...</Text>
        ) : (
          visibleLines.map((line, idx) => (
            <Text key={idx} color={colors.text}>
              {line}
            </Text>
          ))
        )}
      </Box>

      {!isRunning && (
        <Box marginTop={1} justifyContent="center">
          <Text color={colors.primary} bold>
            [ Presiona Enter o Espacio para volver al menú principal ]
          </Text>
        </Box>
      )}
    </Box>
  );
};
