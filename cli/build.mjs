import esbuild from 'esbuild';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const stubPlugin = {
  name: 'stub-devtools',
  setup(build) {
    build.onResolve({ filter: /^react-devtools-core$/ }, (args) => {
      return { path: args.path, namespace: 'devtools-stub' };
    });
    build.onLoad({ filter: /.*/, namespace: 'devtools-stub' }, () => {
      return { contents: 'export default {};', loader: 'js' };
    });
  },
};

async function build() {
  await esbuild.build({
    entryPoints: [path.join(__dirname, 'src/index.tsx')],
    bundle: true,
    platform: 'node',
    target: 'node18',
    format: 'esm',
    outfile: path.join(__dirname, '../dist/cli.mjs'),
    banner: {
      js: `#!/usr/bin/env node
import { createRequire } from 'module';
import { fileURLToPath as __fileURLToPath } from 'url';
import { dirname as __dirnameFunc } from 'path';
const require = createRequire(import.meta.url);
`,
    },
    plugins: [stubPlugin],
    logLevel: 'info',
  });
  console.log('✅ Abbia CLI bundled successfully to dist/cli.mjs');
}

build().catch((err) => {
  console.error('❌ Build failed:', err);
  process.exit(1);
});
