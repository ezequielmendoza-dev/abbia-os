import chalk from 'chalk';

export const colors = {
  primary: '#38bdf8', // Sky 400
  primaryDark: '#0284c7', // Sky 600
  secondary: '#34d399', // Emerald 400
  secondaryDark: '#059669', // Emerald 600
  accent: '#a855f7', // Purple 500
  warning: '#fbbf24', // Amber 400
  error: '#f43f5e', // Rose 500
  text: '#f8fafc', // Slate 50
  textMuted: '#94a3b8', // Slate 400
  textDim: '#64748b', // Slate 500
  bgDark: '#0f172a', // Slate 900
  cardBg: '#1e293b', // Slate 800
  border: '#334155', // Slate 700
};

export const chalkTheme = {
  primary: chalk.hex(colors.primary),
  primaryBold: chalk.hex(colors.primary).bold,
  secondary: chalk.hex(colors.secondary),
  secondaryBold: chalk.hex(colors.secondary).bold,
  accent: chalk.hex(colors.accent),
  warning: chalk.hex(colors.warning),
  error: chalk.hex(colors.error),
  text: chalk.hex(colors.text),
  textMuted: chalk.hex(colors.textMuted),
  textDim: chalk.hex(colors.textDim),
  cardBg: chalk.bgHex(colors.cardBg),
  tag: (text: string) => chalk.bgHex('#0369a1').hex('#f0f9ff').bold(` ${text} `),
  tagSuccess: (text: string) => chalk.bgHex('#065f46').hex('#ecfdf5').bold(` ${text} `),
  tagWarning: (text: string) => chalk.bgHex('#92400e').hex('#fef3c7').bold(` ${text} `),
  tagError: (text: string) => chalk.bgHex('#9f1239').hex('#ffe4e6').bold(` ${text} `),
  tagDim: (text: string) => chalk.bgHex('#334155').hex('#94a3b8')(` ${text} `),
};
