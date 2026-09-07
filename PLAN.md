# Lynx Fast Image port plan

## Objective

Build a custom ReactLynx element named `x-lynx-fast-image` that bypasses Lynx's built-in `<image>` service. It must load through SDWebImage on iOS and Glide on Android while presenting the useful native API of Expo Image 57.0.4.

This is a custom element, not an `LynxServiceImageProtocol`/`ILynxImageService` implementation. The package must not add `LynxService/Image`, `lynx-service-image`, or Fresco. React Native may still contain Fresco for its own built-in image implementation; this element must never route a request through it.

## Pinned upstream

- Package: `expo-image@57.0.4`
- npm tag at import time: `latest`
- Upstream repository: `https://github.com/expo/expo/tree/b76ecf192c5325793bcea31dd9bb8efd91f9ad7f/packages/expo-image`
- Upstream commit: `b76ecf192c5325793bcea31dd9bb8efd91f9ad7f`
- Imported tarball SHA-256: `ea642daaa6e355cdffaf570e6fca195682aae6eca367764c1e6022a47c4847f9`
- License: MIT; retain Expo's copyright headers and `upstream/expo-image/LICENSE`
- Read-only reference snapshot: `upstream/expo-image/`

Do not edit the upstream snapshot. Copy only required behavior into the package's existing `ios/`, `android/`, and `src/` directories. This keeps future upstream comparisons mechanical.

## Current scaffold facts

- The repository has no commits yet; all current files are untracked.
- iOS currently renders a placeholder `UILabel` from `ios/src/LynxFastImageElement.m`.
- Android currently renders a placeholder `TextView` from `android/src/main/java/com/example/lynxfastimage/LynxFastImageElement.java`.
- Android currently references Lynx `0.0.1-alpha.1`, while the consuming `expo-lynx-view` project uses Lynx 4.0.0. Align these before porting code.
- The generated platform module and N-API module are placeholders. Keep only the platform module needed for cache/prefetch operations; the N-API and desktop element paths are outside the mobile image-view milestone.

## Target architecture

```text
ReactLynx <FastImage>
  -> native tag <x-lynx-fast-image>
     -> iOS LynxUI wrapper (Objective-C macros)
        -> renamed Expo Image view logic (Swift)
           -> SDWebImage shared cache/loader
     -> Android LynxUI wrapper (Kotlin)
        -> renamed Expo Image view logic (Kotlin)
           -> Glide
```

Keep `x-lynx-fast-image` instead of registering as `image`; overriding Lynx's built-in tag would make fallback behavior and debugging ambiguous.

## Expo host dependency compatibility

This package is intended to run inside an Expo/React Native host, including hosts that already install `expo-image`. SDWebImage and Glide must resolve as shared host dependencies, not as private or duplicated copies.

- iOS: declare CocoaPods constraints compatible with Expo Image 57.0.4 (`SDWebImage ~> 5.21.0`, `SDWebImageWebPCoder ~> 0.14.6`, and matching optional coder ranges). Do not vendor SDWebImage XCFrameworks or pin an incompatible exact version. Use `SDImageCache.shared` and the process-wide loader/coder managers so Expo Image and Lynx Fast Image share cache state. Coder registration must be idempotent when Expo Image has already registered the same coder.
- Android: use Glide 5.0.5, matching Expo Image 57.0.4, through the normal Gradle dependency graph. Do not shade Glide, bundle its classes, or create a second `AppGlideModule`; Expo Image already provides one. Add a `LibraryGlideModule` only if a required model loader cannot be registered through the existing application configuration, and verify it coexists with Expo's module.
- Do not call Expo Image's internal native view classes. Share the underlying SDWebImage/Glide singleton infrastructure and public library APIs while keeping the Lynx element lifecycle independent.
- Verify compatibility in an actual Expo host both with and without `expo-image` installed. CocoaPods must resolve one version of each SDWebImage pod, and Gradle must resolve one Glide version without duplicate-class or generated-module errors.
- Treat a host dependency conflict as a release blocker. Do not solve it with `force`, exclusions, vendored binaries, or dependency substitution unless the resulting single resolved version is compiled and exercised by both Expo Image and Lynx Fast Image.

## Work order

### 1. Make the scaffold build against the consuming Lynx runtime

1. Pin the iOS pod dependencies to the same Lynx 4.0.x version used by the host. The first integration target uses 4.0.0.
2. Change Android `lynx`, `lynx-processor`, and any retained Lynx artifacts from `0.0.1-alpha.1` to 4.0.0.
3. Remove `LynxServiceAPI` and the placeholder `LynxFastImageService` on both platforms; a custom element does not need an image service.
4. Remove the N-API and desktop backend scaffolding if no consumer uses it. Retain the ordinary platform native module because phase 5 can reuse it for prefetch/cache operations.
5. Add normal ignore rules for `node_modules`, `.gradle`, build products, CocoaPods products, Xcode user data, and generated example output before the first commit.

Check: codegen succeeds and the placeholder element builds in an iOS and Android host before image code is introduced.

### 2. Define the portable ReactLynx surface

Create a `FastImage` wrapper in `src/` and export it from `src/index.ts`. The wrapper renders `x-lynx-fast-image` and owns normalization of public props. Do not expose upstream React Native types directly because `ViewProps`, `StyleProp`, asset IDs, and `SharedRef` are not Lynx contracts.

First supported props:

- `source`: URL string or `{ uri, headers?, cacheKey?, width?, height? }`
- `placeholder`: URL, BlurHash, or ThumbHash source
- `contentFit`: `cover | contain | fill | none | scale-down`
- `placeholderContentFit`
- `contentPosition`
- `transition`
- `blurRadius`
- `tintColor`
- `priority`: `low | normal | high`
- `cachePolicy`: `none | disk | memory | memory-disk`
- `recyclingKey`
- `allowDownscaling`
- `autoplay`
- `decodeFormat`: `argb | rgb`
- `accessibilityLabel`

First supported events:

- `loadstart`
- `progress`: `{ loaded, total, progress }`
- `load`: `{ source: { url, width, height, mediaType? }, cacheType? }`
- `display`
- `error`: `{ error }`

Use Lynx's `bindxxx` convention at the native-tag boundary. The ReactLynx wrapper may expose `onLoadStart`, `onProgress`, `onLoad`, `onDisplay`, and `onError`.

Prefer native object props when Lynx 4.0 passes them consistently to both `NSDictionary` and Android `ReadableMap`. If the example proves otherwise, serialize only `source`, `placeholder`, `contentPosition`, and `transition` as JSON in the wrapper and decode them at the trust boundary. Validate types and URL schemes before starting a native request.

Check: a temporary diagnostic prop round-trips nested source data on both platforms before the image port depends on it.

### 3. Port iOS rendering

Keep `LynxFastImageElement` in Objective-C because Lynx iOS registration, prop, and UI-method APIs are C macros. Return a Swift `LynxFastImageView` from `createView`.

Add compatible pod dependencies based on the pinned upstream:

- `SDWebImage ~> 5.21.0`
- `SDWebImageWebPCoder ~> 0.14.6` when animated WebP is enabled
- Add AVIF/SVG coder pods only in phase 6 when those formats are tested

Port and rename only the necessary upstream types:

- `ImageView.swift`
- `AnimatedImage.swift`
- `ContentFit.swift`
- `ContentPosition.swift`
- `ImageCachePolicy.swift`
- `ImageCacheType.swift`
- `ImagePriority.swift`
- `ImageSource.swift`
- `ImageTransition.swift`
- relevant pieces of `ImageUtils.swift`

Required adaptations:

1. Replace `ExpoView` with `UIView` and remove `ExpoModulesCore`, `AppContext`, Expo `EventDispatcher`, React Native, `SharedRef`, and Expo logging dependencies.
2. Keep `SDAnimatedImageView`, `SDImageCache.shared`, `SDImageLoadersManager.shared`, downsampling, source selection, cache policy, content positioning, transitions, tinting, and cancellation logic where they remain platform-independent.
3. Report callbacks to the Objective-C `LynxUI` wrapper through a small delegate or closures; the wrapper dispatches `LynxDetailEvent` with the element's sign.
4. Implement Lynx prop setters in `LynxFastImageElement.m`; setters update the Swift view and must honor `requestReset`.
5. Cancel the pending SDWebImage operation on source replacement, list-cell reuse/disappearance, view detachment, and deinit. Ignore completion from an older request after a newer source is applied.
6. Reload after a non-zero layout size becomes available and when size changes enough to require a different downsampled image. Never decode a large remote image at original size when the view has resolved dimensions.
7. Support `https`, `http`, `file`, bundled resources used by Lynx releases, and data URLs only after each scheme has a defined cache key and error path.
8. Preserve accessibility labeling and animated-image pause/resume when the element leaves/returns to the visible lifecycle.

Do not initially port SF Symbols, Live Text/VisionKit, photo-library URLs, `ImageRef`, or Expo `SharedRef`. They are not required for remote/bundled mini-app images and add host-framework coupling.

Check: iOS example renders remote JPEG/PNG/WebP/GIF plus a bundled release image; rapid source replacement never flashes a stale result.

### 4. Port Android rendering

Enable Kotlin in `android/build.gradle.kts` and use the upstream-pinned Glide 5.0.5. Do not add Fresco or `lynx-service-image`.

Port and rename the minimum useful upstream code from `upstream/expo-image/android/src/main/java/expo/modules/image/`:

- `ExpoImageView.kt`
- `ExpoImageViewWrapper.kt`
- `ImageViewWrapperTarget.kt`
- `CustomDownsampleStrategy.kt`
- `GlideExtensions.kt`
- source/fit/position/cache/priority/transition records
- request listener and only the model loaders required by supported source schemes

Required adaptations:

1. Replace `ExpoView` with a normal `FrameLayout`; remove `ExpoModulesCore`, `AppContext`, `Promise`, `SharedRef`, and React Native imports.
2. Replace Expo event dispatchers with callbacks to `LynxFastImageElement`, which sends `LynxCustomEvent` payloads matching the TypeScript API.
3. Change the native element from Java `LynxUI<TextView>` to Kotlin `LynxUI<LynxFastImageViewWrapper>` and keep `@LynxElement(name = "x-lynx-fast-image")` plus `@LynxProp` setters.
4. Use `Glide.with(view)` so requests follow the native view lifecycle. Clear both active and placeholder targets on source replacement, reuse, detachment, and destruction.
5. Keep Expo's two-view implementation only if cross-dissolve transitions are included in the first public API; otherwise begin with one image view and add the second when transitions are implemented.
6. Use Glide/Android `Animatable` for autoplay and imperative start/stop. Do not carry Fresco-specific abstractions into the fork.
7. Do not depend on React Native's networking classes. Use Glide's default fetcher initially, or its OkHttp integration if headers/progress require it. Use one client, not a second home-grown downloader.
8. Preserve RGB/ARGB decode selection, bitmap-pool reuse, downsampling, cache policy, and stale-request protection.

Defer Android SVG, AVIF, BlurHash, and ThumbHash model loaders until the basic request lifecycle passes. Add each decoder only with a format fixture and a release-build check.

Check: Gradle dependency output shows this package adds Glide but no Fresco artifact and no Lynx image-service artifact. The host may still contain React Native's Fresco dependencies, but `x-lynx-fast-image` must not use them.

### 5. Repurpose the platform native module for non-view APIs

After the element works, replace the placeholder `setValue/getValue/clear` module API with only the operations that have a real consumer:

- `prefetch(urls, cachePolicy, headers?)`
- `clearMemoryCache()`
- `clearDiskCache()`
- `getCachePath(cacheKey)` when both engines can return a stable local path

Do not port Expo's `useImage`, `loadAsync`, `readFromCacheAsync`, or `writeToCacheAsync` native-image-reference behavior until Lynx has a defined ownership-safe representation for `UIImage`/`Drawable`. Returning an Expo `SharedRef` is not portable to ReactLynx.

Check: prefetch followed by an element load is a warm cache hit on each platform; clear operations complete off the UI thread where required.

### 6. Add optional parity in measured increments

Add only after the core path is stable:

1. BlurHash placeholder
2. ThumbHash placeholder
3. Animated WebP/APNG
4. SVG
5. AVIF
6. Multiple-source selection
7. SF Symbols on iOS
8. BlurHash/ThumbHash generation APIs

Every added decoder must have a fixture and must be tested in a release build. Avoid shipping Expo's prebuilt XCFrameworks/AARs from the npm tarball; resolve source dependencies normally through CocoaPods and Gradle.

### 7. Integration and production checks

Use the existing `example/` first, then integrate the package into the Expo/React Native host that embeds Lynx.

Required cases:

- cold and warm remote JPEG/PNG/WebP/GIF loads
- bundled `static/**` asset from an embedded and managed Lynx release
- placeholder to final-image transition
- rapid `source` changes
- list reuse and repeated mount/unmount
- cancellation after navigation
- authenticated headers without logging secrets
- invalid URL, HTTP error, corrupt bytes, offline, and retry behavior
- very large source downsampled to a small view
- memory warning/background/foreground behavior
- accessibility label announced by VoiceOver/TalkBack
- release builds with shrinking/optimization enabled

Measure the reason for this package: compare a scrolling image list using `x-lynx-fast-image` against the prior built-in path for dropped frames, decode time, peak memory, cache-hit latency, and network request count. Keep the benchmark scenario and result in the repository.

## Definition of done

- `FastImage` renders the same documented core props on iOS and Android.
- No image request goes through Lynx's built-in image service or Fresco.
- Requests cancel correctly and recycled elements cannot display stale images.
- Large images are downsampled to the resolved native view size.
- Load/error/progress payloads match on both platforms.
- Bundled and remote images work in the actual Expo/React Native host.
- The package builds in Debug and Release for iOS simulator/device and Android emulator/device.
- An Expo host can install `expo-image` and `lynx-fast-image` together with one compatible SDWebImage/Glide dependency graph, shared caches, and no duplicate module registration.
- The upstream snapshot remains unchanged and the shipped npm file list excludes `upstream/`.

## Delegation prompt

> Implement `/Users/phirom/Desktop/lynx-fast-image/PLAN.md` in order. Start by aligning the generated scaffold with Lynx 4.0.0 and proving the placeholder custom element builds in the consuming host. Treat `upstream/expo-image/` as read-only Expo Image 57.0.4 reference code. Build `x-lynx-fast-image` directly on SDWebImage for iOS and Glide for Android; do not use Lynx image services or Fresco. Complete and verify one platform phase at a time, preserve request cancellation/downsampling/accessibility, and stop before optional format/API parity unless all core definition-of-done checks pass.
