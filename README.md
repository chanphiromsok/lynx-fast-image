# lynx-fast-image

Custom Lynx element `<x-lynx-fast-image>` that renders images through
SDWebImage (iOS) and Glide (Android) instead of Lynx's built-in `<image>`
service. It exposes the useful parts of the Expo Image API to ReactLynx.

This is a custom native component, **not** a `LynxServiceImageProtocol` /
`ILynxImageService` implementation. It never adds `LynxService/Image`,
`lynx-service-image`, or Fresco, and never routes a request through them.

## Development

```bash
npm install
npm run codegen
```

`npm run codegen` (`lynx-autolink-codegen`) regenerates the platform native
module spec/facade from `types/platform-native-module.d.ts` and `lynx.lib.json`:

- `generated/LynxFastImageModule.ts` — BTS TypeScript facade
- `ios/src/generated/LynxFastImageModuleSpec.{h,m}`
- `android/src/main/java/com/example/lynxfastimage/generated/LynxFastImageModuleSpec.java`

## Layout

- `src/` — ReactLynx wrapper and public TypeScript API
- `ios/` — Objective-C `LynxUI` wrapper + Swift view logic
- `android/` — Kotlin `LynxUI` wrapper + view logic
- `types/` — platform native module typings (`@lynxmodule`)
- `upstream/expo-image/` — read-only Expo Image 57.0.4 reference snapshot
  (not shipped; see `package.json` `files`)

## Native dependencies

Both engines resolve as shared host dependencies, matching Expo Image 57.0.4:

- iOS: `Lynx 4.0.0`, `SDWebImage ~> 5.21.0` (added in the iOS rendering phase)
- Android: `org.lynxsdk.lynx:lynx:4.0.0`, Glide `5.0.5` (added in the Android
  rendering phase)

The consuming host currently integrated against is `expo-lynx-view` on
Lynx `4.0.0`.
