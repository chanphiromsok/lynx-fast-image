package com.example.lynxfastimage;

import android.content.Context;
import android.widget.TextView;
import com.lynx.tasm.behavior.LynxContext;
import com.lynx.tasm.behavior.LynxElement;
import com.lynx.tasm.behavior.ui.LynxUI;

@LynxElement(name = "x-lynx-fast-image")
public class LynxFastImageElement extends LynxUI<TextView> {
  public LynxFastImageElement(LynxContext context) {
    super(context);
  }

  @Override
  protected TextView createView(Context context) {
    TextView view = new TextView(context);
    view.setText("x-lynx-fast-image");
    return view;
  }
}
