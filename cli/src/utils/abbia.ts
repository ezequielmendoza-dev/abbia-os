import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';

export interface InitiativeInfo {
  id: string;
  folderName: string;
  fullPath: string;
  hasSpec: boolean;
  hasArch: boolean;
  hasPlan: boolean;
  hasTest: boolean;
  hasDev: boolean;
  hasQa: boolean;
  qaVerdict?: 'APROBADO' | 'APROBADO_CON_OBSERVACIONES' | 'RECHAZADO' | 'PENDIENTE';
  qaDetails?: string;
  isReadyToArchive: boolean;
}

export interface ProjectInfo {
  root: string;
  coreDir: string;
  scriptsDir: string;
  projectName: string;
  gitBranch: string;
  initiatives: InitiativeInfo[];
  archivedCount: number;
}

export function findProjectRoot(startDir: string = process.cwd()): string {
  let current = path.resolve(startDir);
  while (true) {
    if (fs.existsSync(path.join(current, '.abbia'))) {
      return current;
    }
    // Also support running inside the core repository itself
    if (fs.existsSync(path.join(current, 'roles')) && fs.existsSync(path.join(current, 'scripts', 'finish-phase.sh'))) {
      return current;
    }
    const parent = path.dirname(current);
    if (parent === current) {
      break;
    }
    current = parent;
  }
  return path.resolve(startDir);
}

export function getProjectInfo(projectRoot: string): ProjectInfo {
  const isCoreRepo = fs.existsSync(path.join(projectRoot, 'roles')) && fs.existsSync(path.join(projectRoot, 'scripts', 'finish-phase.sh'));
  const coreDir = isCoreRepo ? projectRoot : path.join(projectRoot, '.abbia', 'core');
  const scriptsDir = isCoreRepo ? path.join(projectRoot, 'scripts') : path.join(coreDir, 'scripts');

  let projectName = path.basename(projectRoot);
  try {
    const pkgPath = path.join(projectRoot, 'package.json');
    if (fs.existsSync(pkgPath)) {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
      if (pkg.name) projectName = pkg.name;
    }
  } catch {}

  let gitBranch = 'unknown';
  try {
    const headPath = path.join(projectRoot, '.git', 'HEAD');
    if (fs.existsSync(headPath)) {
      const headContent = fs.readFileSync(headPath, 'utf8').trim();
      if (headContent.startsWith('ref: refs/heads/')) {
        gitBranch = headContent.replace('ref: refs/heads/', '');
      } else {
        gitBranch = headContent.slice(0, 7);
      }
    }
  } catch {}

  const initiativesDir = isCoreRepo
    ? path.join(projectRoot, 'examples', 'golden-project', '.abbia', 'initiatives')
    : path.join(projectRoot, '.abbia', 'initiatives');

  const initiatives: InitiativeInfo[] = [];

  if (fs.existsSync(initiativesDir)) {
    const entries = fs.readdirSync(initiativesDir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory() || entry.name.startsWith('.')) continue;
      const fullPath = path.join(initiativesDir, entry.name);
      const hasSpec = fs.existsSync(path.join(fullPath, '1-spec.md'));
      const hasArch = fs.existsSync(path.join(fullPath, '2-arch.md'));
      const hasPlan = fs.existsSync(path.join(fullPath, '3-plan.md'));
      const hasTest = fs.existsSync(path.join(fullPath, '4-test.md'));
      const hasDev = fs.existsSync(path.join(fullPath, '5-dev.md'));
      const qaPath = path.join(fullPath, '6-qa.md');
      const hasQa = fs.existsSync(qaPath);

      let qaVerdict: InitiativeInfo['qaVerdict'] = 'PENDIENTE';
      let qaDetails = '';
      if (hasQa) {
        try {
          const qaContent = fs.readFileSync(qaPath, 'utf8');
          if (/verdict:\s*["']?APROBADO["']?/i.test(qaContent) || /###\s*Veredicto[:\s]*\**APROBADO\**/i.test(qaContent)) {
            qaVerdict = 'APROBADO';
          } else if (/verdict:\s*["']?APROBADO CON OBSERVACIONES["']?/i.test(qaContent) || /APROBADO CON OBSERVACIONES/i.test(qaContent)) {
            qaVerdict = 'APROBADO_CON_OBSERVACIONES';
          } else if (/verdict:\s*["']?RECHAZADO["']?/i.test(qaContent) || /RECHAZADO/i.test(qaContent)) {
            qaVerdict = 'RECHAZADO';
          }
        } catch {}
      }

      initiatives.push({
        id: entry.name,
        folderName: entry.name,
        fullPath,
        hasSpec,
        hasArch,
        hasPlan,
        hasTest,
        hasDev,
        hasQa,
        qaVerdict,
        qaDetails,
        isReadyToArchive: qaVerdict === 'APROBADO' || qaVerdict === 'APROBADO_CON_OBSERVACIONES',
      });
    }
  }

  let archivedCount = 0;
  const archiveDir = isCoreRepo
    ? path.join(projectRoot, 'examples', 'golden-project', '.abbia', 'archive')
    : path.join(projectRoot, '.abbia', 'archive');
  if (fs.existsSync(archiveDir)) {
    try {
      archivedCount = fs.readdirSync(archiveDir, { withFileTypes: true }).filter((d) => d.isDirectory() && !d.name.startsWith('.')).length;
    } catch {}
  }

  return {
    root: projectRoot,
    coreDir,
    scriptsDir,
    projectName,
    gitBranch,
    initiatives,
    archivedCount,
  };
}

export function executeAbbiaScript(
  scriptName: string,
  args: string[],
  projectRoot: string,
  onData: (text: string) => void,
  onExit: (code: number) => void
) {
  const info = getProjectInfo(projectRoot);
  const scriptPath = path.join(info.scriptsDir, scriptName);

  if (!fs.existsSync(scriptPath)) {
    onData(`\x1b[31mError: No se encontró el script en ${scriptPath}\x1b[0m\n`);
    onExit(1);
    return;
  }

  const proc = spawn('bash', [scriptPath, ...args], {
    cwd: projectRoot,
    env: { ...process.env, PROJECT_ROOT: projectRoot },
  });

  proc.stdout?.on('data', (d) => onData(d.toString()));
  proc.stderr?.on('data', (d) => onData(d.toString()));

  proc.on('close', (code) => {
    onExit(code ?? 0);
  });

  return proc;
}
