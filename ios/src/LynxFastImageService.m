#import "LynxFastImageService.h"

@LynxServiceRegister(LynxFastImageService, LynxFastImageServiceProtocol)
@implementation LynxFastImageService

- (NSString *)name {
  return @"LynxFastImageService";
}

@end
