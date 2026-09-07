import { pluginReactLynx } from "@lynx-js/react-rsbuild-plugin";
import { defineConfig } from "@lynx-js/rspeedy";

export default defineConfig({
  source: {
    entry: {
      main: "./src/index.tsx",
    },
    // `lynx-fast-image` is linked via `file:..` and ships TypeScript source
    // (`main` -> `src/index.ts`). SWC skips `node_modules` by default, so opt the
    // linked package's source back in for transpilation.
    include: [/[\\/]lynx-fast-image[\\/]src[\\/]/],
  },
  plugins: [pluginReactLynx()],
});
