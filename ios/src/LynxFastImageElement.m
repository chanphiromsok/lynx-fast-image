#import "LynxFastImageElement.h"

@implementation LynxFastImageElement

- (UILabel *)createView {
  UILabel *label = [[UILabel alloc] init];
  label.text = @"x-lynx-fast-image";
  return label;
}

@end
