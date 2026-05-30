---
name: vite-plugin-federation
description: Module Federation with @originjs/vite-plugin-federation for Vite + Vue 3. Use when configuring host/remote apps, sharing singleton dependencies, lazy-loading remotes, or debugging federation runtime errors.
---

# Vite Plugin Federation (@originjs/vite-plugin-federation)

Patterns and constraints for Module Federation in Vite monorepos. Source: originjs/vite-plugin-federation official docs.

## Non-Negotiable Build Config

Both host and remote **must** set these in `vite.config.ts`:

```ts
build: {
  target: 'esnext',      // Required — federation uses top-level await + dynamic imports
  modulePreload: false,
  cssCodeSplit: false,   // Required on remotes — prevents CSS extraction issues
  minify: false,         // Recommended during development
}
```

Alternative targets (if esnext is blocked):
```ts
build: {
  target: ['chrome89', 'edge89', 'firefox89', 'safari15']
}
```

## Remote Configuration

```ts
// vite.config.ts — remote app
import federation from '@originjs/vite-plugin-federation'

export default defineConfig({
  plugins: [
    vue(),
    federation({
      name: 'remote-app',
      filename: 'remoteEntry.js',
      exposes: {
        './Button': './src/components/Button.vue',
      },
      shared: ['vue', 'vue-router', 'pinia'], // singleton by default
    }),
  ],
  build: {
    target: 'esnext',
    modulePreload: false,
    cssCodeSplit: false,
  },
})
```

## Host Configuration

```ts
// vite.config.ts — shell/host app
import federation from '@originjs/vite-plugin-federation'

export default defineConfig({
  plugins: [
    vue(),
    federation({
      name: 'host-app',
      remotes: {
        remote_app: 'http://localhost:5001/assets/remoteEntry.js',
      },
      shared: ['vue', 'vue-router', 'pinia'],
    }),
  ],
  build: {
    target: 'esnext',
  },
})
```

## Dynamic Remote URLs (Promise-based)

```ts
remotes: {
  home: {
    external: `Promise.resolve('your url')`,
    externalType: 'promise',
  },
  // or from network
  remote_app: {
    external: `fetch('/config').then(r => r.json()).then(d => d.remoteUrl)`,
    externalType: 'promise',
  },
},
```

## TypeScript Declarations

Declare remote modules to silence "Cannot find module" errors:

```ts
// src/types/remotes.d.ts
declare module 'remote_app/*' {}
```

Declare the federation virtual module for dynamic loading:

```ts
declare module 'virtual:__federation__' {
  interface IRemoteConfig {
    url: (() => Promise<string>) | string
    format: 'esm' | 'systemjs' | 'var'
    from: 'vite' | 'webpack'
  }
  export function __federation_method_setRemote(name: string, config: IRemoteConfig): void
  export function __federation_method_getRemote(name: string, exposedPath: string): Promise<unknown>
  export function __federation_method_unwrapDefault(module: unknown): Promise<unknown>
  export function __federation_method_ensure(remoteName: string): Promise<unknown>
}
```

## Lazy-Loading Remotes in Vue Router

```ts
// router/index.ts
const routes = [
  {
    path: '/remote-feature',
    component: () => import('remote_app/MyView'),
  },
]
```

## Shared — Reduce Bundle Size

Use `generate: false` on remotes when the host already provides the shared dep:

```ts
shared: {
  vue: {
    generate: false, // Don't re-bundle on remote side — host provides it
  },
}
```

## Critical Rules

| Rule | Why |
|------|-----|
| `build.target: 'esnext'` on both sides | Federation relies on top-level `await` — lower targets break remote containers |
| `cssCodeSplit: false` on remotes | Without this, CSS gets extracted into separate chunks the host never loads |
| Share `vue`, `vue-router`, `pinia` | Two Vue instances = broken reactivity with no error message |
| `modulePreload: false` on remotes | Prevents preload link injection that conflicts with federation loading |

## Dev vs Build Difference

In **dev mode**, remotes are fetched live from the URL — fast but masks some issues. In **build mode**, the host references `remoteEntry.js` statically. Always verify the **built** output before shipping.
