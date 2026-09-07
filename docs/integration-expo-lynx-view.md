# Using lynx-fast-image inside expo-lynx-view

Decision (chosen): **Expo module + monorepo workspace**, and consumers
**import `FastImage` directly from `lynx-fast-image`** (no re-export from
`expo-lynx-view`).

The element renders native (SDWebImage). So the host app must build pods —
bare RN, `expo prebuild`, or a native iOS target. It will not run in a
managed Expo app with no native build, or a prebuilt Lynx Explorer.

---

## What makes it "part of expo-lynx-view"

Three hooks:

1. **Package graph** — `expo-lynx-view` depends on `lynx-fast-image`, so any
   app that installs `expo-lynx-view` gets `lynx-fast-image` in
   `node_modules`.
2. **Pod autolinking** — `lynx-fast-image` now ships `expo-module.config.json`
   (`platforms: ["apple"]`, `apple.podspecPath: ios/lynx-fast-image.podspec`).
   Expo's apple autolinking scans `node_modules` for that file and adds the
   pod to the app Podfile automatically — no `pod '…', :path` line for the
   consumer to write. SDWebImage comes in as the podspec dependency.
3. **Element registration** — `ExpoLynxView.swift` registers
   `x-lynx-fast-image` on every `LynxView` it builds, by runtime class name so
   it stays a soft dependency.

The JS `<FastImage>` wrapper is plain ReactLynx — it needs no bridge to
`expo-lynx-view`, which is why we don't re-export it.

---

## Step 1 — bring lynx-fast-image into the monorepo

`pnpm` workspace packages must live under a `pnpm-workspace.yaml` glob
(`packages/*`). Add it as a **git submodule** so it keeps its own repo and
release cadence:

```bash
cd /Users/phirom/Desktop/expo-lynx-monorepo
git submodule add https://github.com/chanphiromsok/lynx-fast-image.git packages/lynx-fast-image
pnpm install
```

(`packages/lynx-fast-image` is matched by the existing `packages/*` glob — no
`pnpm-workspace.yaml` change needed.)

Requires the 3 local commits in lynx-fast-image to be pushed first.

## Step 2 — depend on it from expo-lynx-view

`packages/expo-lynx/package.json`:

```jsonc
"dependencies": {
  "lynx-fast-image": "workspace:*"
}
```

Add `lynx-fast-image`'s peer to the example app so the mini-app bundle build
can resolve it:

`apps/expo-lynx-example/package.json` → `dependencies`:

```jsonc
"lynx-fast-image": "workspace:*",
"@lynx-js/react": "<same range the mini-app uses>"
```

## Step 3 — link the pod (podspec dependency)

`packages/expo-lynx/ios/ExpoLynx.podspec` — add next to the other Lynx deps:

```ruby
s.dependency 'lynx-fast-image'
```

Autolinking already writes `pod 'lynx-fast-image', :path => …` into the
Podfile from `expo-module.config.json`; this line just makes the intent
explicit and pins build order. `s.static_framework = true` on `ExpoLynx` is
fine — `lynx-fast-image`'s pod is a plain static lib with a plain ObjC
protocol bridge (`LynxFastImageViewProtocol.h`) and instantiates its Swift
view via `NSClassFromString`, so it has no `-Swift.h` umbrella to break
under static frameworks.

## Step 4 — register the element

`packages/expo-lynx/ios/View/ExpoLynxView.swift`, inside the existing
`lynxView = LynxView { builder in … }` block, right after
`builder.config = LynxConfig(provider: provider)`:

```swift
// lynx-fast-image: render <x-lynx-fast-image> through SDWebImage. Soft
// reference — the class is present whenever the pod is linked, and the
// element is a no-op if it isn't.
if let elementClass = NSClassFromString("LynxFastImageElement") {
  builder.config?.registerUI(elementClass, withName: "x-lynx-fast-image")
}
```

No `import lynx_fast_image` — keep it a runtime lookup so `ExpoLynx` compiles
even in a build that excludes the pod.

## Step 5 — the mini-app side

The mini-app bundle (the rspeedy project whose `.lynx.bundle` the LynxView
loads) is what actually uses `<FastImage>`:

```tsx
import { FastImage } from "lynx-fast-image";

<FastImage source={mySource} contentFit="cover" onLoad={…} onError={…} />
```

`lynx-fast-image` currently ships **TypeScript source** (`main` →
`src/index.ts`), so the mini-app's `lynx.config.ts` must opt it into
transpilation:

```ts
source: {
  include: [/[\\/]lynx-fast-image[\\/]src[\\/]/],
}
```

Follow-up worth doing: add a build step so `lynx-fast-image` ships compiled
JS in `dist/` and this `include` is no longer required by every consumer.

---

## Verify

1. `pnpm install` at the monorepo root resolves `lynx-fast-image` as a
   workspace package.
2. `cd apps/expo-lynx-example && npx expo prebuild -p ios --clean` then
   `pod install` — the Podfile.lock lists `lynx-fast-image` and `SDWebImage`,
   and CocoaPods resolves a single `SDWebImage` version shared with any
   `expo-image`.
3. Point the example app's LynxView at a mini-app bundle that renders
   `<FastImage>`; the image loads and `onLoad` fires with the Expo-shaped
   payload.
4. Known caveat: the full Expo host previously hit an unrelated RN Fabric
   prebuilt-core linker error (`DebugStringConvertible` / `Sealable`). If it
   recurs it is not from this pod — the standalone `example/ios` host in the
   lynx-fast-image repo stays the isolation baseline.
