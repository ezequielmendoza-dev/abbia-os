import React, { useState, useEffect } from 'react';
import { render, Box, useApp } from 'ink';
import { findProjectRoot, getProjectInfo, ProjectInfo } from './utils/abbia.js';
import { Header } from './components/Header.js';
import { MainMenu } from './screens/MainMenu.js';
import { NewInitiativeScreen } from './screens/NewInitiativeScreen.js';
import { FinishPhaseScreen } from './screens/FinishPhaseScreen.js';
import { ArchiveScreen } from './screens/ArchiveScreen.js';
import { InitiativesListScreen } from './screens/InitiativesListScreen.js';
import { HelpScreen } from './screens/HelpScreen.js';
import { ActionRunner } from './screens/ActionRunner.js';
import { spawn } from 'child_process';
import path from 'path';

type ScreenState =
  | 'menu'
  | 'new'
  | 'list'
  | 'finish'
  | 'archive'
  | 'help'
  | 'action_sync'
  | 'action_validate'
  | 'action_dashboard'
  | 'action_update'
  | 'action_custom';

interface CustomActionConfig {
  title: string;
  scriptName: string;
  args: string[];
}

const App: React.FC = () => {
  const { exit } = useApp();
  const [projectRoot, setProjectRoot] = useState<string>(() => findProjectRoot());
  const [projectInfo, setProjectInfo] = useState<ProjectInfo>(() => getProjectInfo(projectRoot));
  const [screen, setScreen] = useState<ScreenState>('menu');
  const [customAction, setCustomAction] = useState<CustomActionConfig | null>(null);

  const refreshInfo = () => {
    setProjectInfo(getProjectInfo(projectRoot));
  };

  const handleMenuSelect = (value: string) => {
    switch (value) {
      case 'new':
        setScreen('new');
        break;
      case 'list':
        setScreen('list');
        break;
      case 'finish':
        setScreen('finish');
        break;
      case 'archive':
        setScreen('archive');
        break;
      case 'sync':
        setScreen('action_sync');
        break;
      case 'validate':
        setScreen('action_validate');
        break;
      case 'dashboard':
        setScreen('action_dashboard');
        break;
      case 'update':
        setScreen('action_update');
        break;
      case 'help':
        setScreen('help');
        break;
      case 'exit':
        exit();
        process.exit(0);
        break;
      default:
        break;
    }
  };

  const handleActionDone = () => {
    refreshInfo();
    setScreen('menu');
    setCustomAction(null);
  };

  return (
    <Box flexDirection="column" padding={1}>
      <Header
        projectInfo={projectInfo}
        currentScreen={
          screen === 'menu'
            ? 'Panel Principal'
            : screen === 'new'
            ? 'Nueva Iniciativa'
            : screen === 'list'
            ? 'Iniciativas'
            : screen === 'finish'
            ? 'Cerrar Fase'
            : screen === 'archive'
            ? 'Archivar'
            : screen === 'help'
            ? 'Ayuda'
            : 'Ejecutando'
        }
      />

      {screen === 'menu' && (
        <MainMenu projectInfo={projectInfo} onSelect={handleMenuSelect} />
      )}

      {screen === 'new' && (
        <NewInitiativeScreen
          onCancel={() => setScreen('menu')}
          onSubmit={(type, id, slug) => {
            setCustomAction({
              title: `Crear Iniciativa: ${type}-${id}-${slug}`,
              scriptName: 'new-initiative.sh',
              args: [type, id, slug],
            });
            setScreen('action_custom');
          }}
        />
      )}

      {screen === 'list' && (
        <InitiativesListScreen
          projectInfo={projectInfo}
          onBack={() => setScreen('menu')}
        />
      )}

      {screen === 'finish' && (
        <FinishPhaseScreen
          projectInfo={projectInfo}
          onCancel={() => setScreen('menu')}
          onSubmit={(args) => {
            setCustomAction({
              title: `Cerrar Fase: ${args[0]} (${args[1]})`,
              scriptName: 'finish-phase.sh',
              args,
            });
            setScreen('action_custom');
          }}
        />
      )}

      {screen === 'archive' && (
        <ArchiveScreen
          projectInfo={projectInfo}
          onCancel={() => setScreen('menu')}
          onSubmit={(initName) => {
            setCustomAction({
              title: `Archivar Iniciativa: ${initName}`,
              scriptName: 'archive-initiative.sh',
              args: [initName],
            });
            setScreen('action_custom');
          }}
        />
      )}

      {screen === 'help' && <HelpScreen onBack={() => setScreen('menu')} />}

      {screen === 'action_sync' && (
        <ActionRunner
          title="Sincronizar y Reparar Iniciativas"
          scriptName="sync-initiatives.sh"
          args={['--fix']}
          projectRoot={projectRoot}
          onDone={handleActionDone}
        />
      )}

      {screen === 'action_validate' && (
        <ActionRunner
          title="Validar Proyecto Abbia OS"
          scriptName="validate-project.sh"
          args={[]}
          projectRoot={projectRoot}
          onDone={handleActionDone}
        />
      )}

      {screen === 'action_dashboard' && (
        <ActionRunner
          title="Generar Dashboard Visual"
          scriptName="dashboard.sh"
          args={[]}
          projectRoot={projectRoot}
          onDone={handleActionDone}
        />
      )}

      {screen === 'action_update' && (
        <ActionRunner
          title="Actualizar Abbia OS Framework"
          scriptName="update-abbia.sh"
          args={[]}
          projectRoot={projectRoot}
          onDone={handleActionDone}
        />
      )}

      {screen === 'action_custom' && customAction && (
        <ActionRunner
          title={customAction.title}
          scriptName={customAction.scriptName}
          args={customAction.args}
          projectRoot={projectRoot}
          onDone={handleActionDone}
        />
      )}
    </Box>
  );
};

// Direct command dispatch if arguments are supplied via CLI
function runCli() {
  const args = process.argv.slice(2);
  if (args.length === 0 || args[0] === '-i' || args[0] === '--interactive') {
    render(<App />);
    return;
  }

  const root = findProjectRoot();
  const info = getProjectInfo(root);
  const command = args[0];
  const commandArgs = args.slice(1);

  let scriptName = '';
  switch (command) {
    case 'new':
      scriptName = 'new-initiative.sh';
      break;
    case 'finish':
      scriptName = 'finish-phase.sh';
      break;
    case 'archive':
      scriptName = 'archive-initiative.sh';
      break;
    case 'sync':
      scriptName = 'sync-initiatives.sh';
      break;
    case 'validate':
      scriptName = 'validate-project.sh';
      break;
    case 'dashboard':
      scriptName = 'dashboard.sh';
      break;
    case 'update':
      scriptName = 'update-abbia.sh';
      break;
    case 'setup':
      scriptName = 'setup-ide.sh';
      break;
    case 'help':
    case '--help':
    case '-h':
      console.log(`
🏛️  Abbia OS CLI v4.0.0
Uso:
  ./abbia                        Abre el dashboard interactivo (TUI)
  ./abbia new <tipo> <id> <slug> Crea una nueva iniciativa
  ./abbia finish <init> <fase>   Cierra una fase y registra telemetría
  ./abbia archive <init>         Archiva una iniciativa aprobada
  ./abbia sync [--fix]           Sincroniza y repara iniciativas
  ./abbia validate               Valida la salud y memoria del proyecto
  ./abbia dashboard              Abre el visualizador web interactivo
  ./abbia update                 Actualiza el framework
`);
      process.exit(0);
      break;
    default:
      console.error(`Comando desconocido: ${command}. Usa ./abbia --help`);
      process.exit(1);
  }

  const scriptPath = path.join(info.scriptsDir, scriptName);
  const proc = spawn('bash', [scriptPath, ...commandArgs], {
    stdio: 'inherit',
    cwd: root,
    env: { ...process.env, PROJECT_ROOT: root },
  });

  proc.on('close', (code) => {
    process.exit(code ?? 0);
  });
}

runCli();
