#include <lynx/registration.h>

#include "shared/elements/LynxFastImageElement.h"

LYNX_REGISTER_ELEMENT(
    "LynxFastImageElementModule",
    "x-lynx-fast-image",
    CreateLynxFastImageElementNativeView,
    false,
    nullptr)
