package com.example.lynxfastimage;

import androidx.annotation.Nullable;
import com.lynx.jsbridge.LynxMethod;
import com.lynx.jsbridge.LynxNativeModule;
import com.lynx.tasm.behavior.LynxContext;
import com.example.lynxfastimage.generated.LynxFastImageModuleSpec;

@LynxNativeModule(name = "LynxFastImageModule")
public class LynxFastImageModule extends LynxFastImageModuleSpec {
  public LynxFastImageModule(LynxContext context) {
    super(context);
  }

  @Override
  @LynxMethod
  public void setValue(String key, String value) {
  }

  @Override
  @LynxMethod
  @Nullable
  public String getValue(String key) {
    return null;
  }

  @Override
  @LynxMethod
  public void clear() {
  }
}
