import { LynxFastImageModule, LynxFastImageModuleNapi } from 'lynx-fast-image';

export function App() {
  return (
    <view>
      <text>lynx-fast-image</text>
      <text bindtap={() => LynxFastImageModule.setValue('key', 'value')}>
        Native module
      </text>
      <text bindtap={() => LynxFastImageModuleNapi.setValue('key', 'value')}>
        NAPI native module
      </text>
      <x-lynx-fast-image />
    </view>
  );
}
