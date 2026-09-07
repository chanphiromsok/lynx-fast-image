# Handoff — iOS native module (PLAN Phase 5)

**Status:** not started. The Phase‑1 placeholder module has been **removed** from
the working tree (`ios/src/LynxFastImageModule.{h,m}`,
`ios/src/generated/LynxFastImageModuleSpec.*`, `generated/LynxFastImageModule.ts`
are all deleted) so the element can build without it. The codegen typings in
`types/` still describe the old `setValue`/`getValue`/`clear` shape — rewrite
those first (below) and `pnpm codegen` regenerates every removed file.
**Scope:** repurpose `LynxFastImageModule` into the non‑view cache/prefetch API.
Do **not** touch the element (`x-lynx-fast-image`) or its Swift view — that is
Phase 3.

---

## Target API

Port only the four operations that have a real consumer (PLAN §5). Model them on
`upstream/expo-image/ios/ImageModule.swift`, but Lynx has no `Promise` type in
its module ABI, so use a **trailing callback param** instead of a promise
return.

| JS method | upstream analogue | notes |
|---|---|---|
| `prefetch(urls, cachePolicy, headers, callback)` | `AsyncFunction("prefetch")` @ line 182 | `callback(ok: boolean)` — resolves `false` if any URL was skipped |
| `clearMemoryCache(callback)` | `AsyncFunction("clearMemoryCache")` @ 230 | `SDImageCache.shared.clearMemory()`, then `callback(true)` |
| `clearDiskCache(callback)` | `AsyncFunction("clearDiskCache")` @ 235 | `SDImageCache.shared.clearDisk { callback(true) }` |
| `getCachePath(cacheKey, callback)` | `AsyncFunction("getCachePathAsync")` @ 241 | `diskImageExists(withKey:)` → `callback(path)` or `callback(nil)` |

Skip `configureCache`, `generateBlurhashAsync`, `generateThumbhashAsync`,
`writeToCacheAsync`, `readFromCacheAsync`, `loadAsync` — deferred / not portable
(they return Expo `SharedRef`).

---

## Codegen flow (this is the important part)

The spec is **generated**, not hand‑written. Source of truth:

    types/platform-native-module.d.ts

```ts
/** @lynxmodule */
export declare class LynxFastImageModule {
  prefetch(
    urls: string[],
    cachePolicy: string,
    headers: Record<string, string> | null,
    callback: (ok: boolean) => void
  ): void;
  clearMemoryCache(callback: (ok: boolean) => void): void;
  clearDiskCache(callback: (ok: boolean) => void): void;
  getCachePath(cacheKey: string, callback: (path: string | null) => void): void;
}
```

Then:

```bash
pnpm codegen   # -> lynx-autolink-codegen
```

regenerates:

- `generated/LynxFastImageModule.ts` — BTS facade (`NativeModules.LynxFastImageModule`)
- `ios/src/generated/LynxFastImageModuleSpec.h` / `.m` — the `@protocol LynxFastImageModuleSpec`

**Codegen type mapping (iOS)** — from `@lynx-js/autolink-codegen@0.4.1`:

| d.ts type | ObjC param | ObjC return |
|---|---|---|
| `string` | `NSString *` | `NSString *` |
| `string \| null` | `nullable NSString *` | `nullable NSString *` |
| `number` | `double` | `double` |
| `boolean` | `BOOL` | `BOOL` |
| `string[]`, `Record<>`, `(x)=>void`, `Promise<>` | **`id`** | `nullable id` |

So `urls: string[]` arrives as `NSArray<NSString *> *` boxed in `id`,
`headers` as `NSDictionary *` (or `NSNull`/`nil`), and `callback` as a
`LynxCallbackBlock` (`typedef void (^)(id result)` — see
`Lynx/module/LynxModule.h`). Cast them in the method body.

---

## Implementation checklist

1. **Edit** `types/platform-native-module.d.ts` as above. Run `pnpm codegen`.
   Confirm `LynxFastImageModuleSpec.h` now lists the four selectors.
2. **Rewrite** `ios/src/LynxFastImageModule.m`:
   - `+ methodLookup` — map the 4 JS names to
     `prefetch:cachePolicy:headers:callback:` etc.
   - Each method: cast `id` args, build an `SDWebImageContext` exactly like
     upstream `prefetch` (the `queryCacheType`/`storeCacheType` /
     `originalQueryCacheType` dance matters — a naive `prefetchURLs:` ignores
     `cachePolicy`), invoke the `LynxCallbackBlock` on completion.
   - `ImageCachePolicy` is a **Swift** enum. Either duplicate the tiny
     `String -> SDImageCacheType` switch in ObjC, or expose a
     `+ (SDImageCacheType)sdCacheTypeForPolicyString:` shim from
     `LynxFastImageViewBridge.swift`. Prefer the shim — keeps one source of
     truth (`ImageCachePolicy.toSdCacheType()` already exists).
   - `#import <SDWebImage/SDWebImage.h>` — the podspec already depends on it,
     and the Podfile marks it `:modular_headers`.
3. **Keep `LynxFastImageModule.h`** as the thin `@LynxNativeModule("LynxFastImageModule")`
   marker + `<LynxFastImageModuleSpec>` conformance. Flat `#import "LynxFastImageModuleSpec.h"`
   (CocoaPods flattens headers — do not use the `generated/` path).
4. **Register it in the host.** The standalone `example/ios` host currently
   registers only the UI element + `LynxWebSocketModule`. Add, in
   `LynxPlayerViewController`'s `LynxView { builder in ... }` (or wherever the
   real Expo host builds its `LynxConfig`):
   ```swift
   if let m = NSClassFromString("LynxFastImageModule") as? LynxModule.Type {
     builder.config?.register(m)
   }
   ```
   `@LynxNativeModule` is a **marker only** in 4.0.0 — nothing auto‑registers
   (same as the element). Also check `@LynxNativeModuleRegister` is *not*
   reintroduced; it does not exist in 4.0.0 (see the element history).
5. **Static‑lib linkage.** The module class is ObjC; `-ObjC` in the app
   xcconfig keeps it. No `-force_load` needed (that was only for
   `@LynxServiceRegister`'s `__LYNX__DATA` section).

---

## Verification (PLAN §5 "Check")

Add a background‑only script (`example/src/` — import from
`lynx-fast-image/generated/LynxFastImageModule`, **never** from the package
root; the facade reads `NativeModules.*` at eval time and throws on the main
thread — see the note in `src/index.ts`):

1. `prefetch([url], "disk", null, ok => ...)` → then mount `<FastImage source={url}>`
   → `load` event fires with **`cacheType: "disk"`** (warm hit, no network — check
   with the DevTool network panel or Charles).
2. `clearMemoryCache` then remount same URL → still a disk hit, not network.
3. `clearDiskCache` then remount → network fetch again.
4. `getCachePath(knownKey, p => ...)` → non‑nil path that exists on disk;
   unknown key → `null`.
5. All callbacks must land off the render path — `clearDisk` is already async in
   SDWebImage; just don't block in the method body.

---

## Gotchas carried over from Phase 1–3

- `@LynxNativeModule` / `@LynxElement` are **markers**, not registrars (Lynx
  4.0.0). Host must `builder.config.register(...)` / `registerUI(...)`.
- Do not re‑export the module from `src/index.ts` (main‑thread eval crash).
- `pnpm codegen` overwrites `generated/` and `ios/src/generated/` — keep the
  hand‑written `.m` in sync manually; codegen never writes the impl.
- `package.json` `files` currently lists `generated/` — fine, but the deleted
  N‑API generated files should stay deleted; codegen for a *platform* module
  (not NAPI) won't recreate them.
