export { FastImage } from './FastImage';
export type {
  FastImageProps,
  FastImageSource,
  FastImageContentFit,
  FastImageContentPosition,
  FastImageTransition,
  FastImagePriority,
  FastImageCachePolicy,
  FastImageDecodeFormat,
  FastImageLoadEvent,
  FastImageProgressEvent,
  FastImageErrorEvent,
} from './FastImage';

// NOTE: the platform native module (`LynxFastImageModule`, used in Phase 5 for
// prefetch / cache ops) is intentionally NOT re-exported here. Its generated
// facade reads `NativeModules.LynxFastImageModule` at module-eval time, which
// only exists in the background (BTS) runtime — importing it from a component
// that also renders on the main thread throws
// "cannot read property 'LynxFastImageModule' of undefined".
// Import it directly from 'lynx-fast-image/generated/LynxFastImageModule' in
// background-only code once that milestone lands.
