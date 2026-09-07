#import <Foundation/Foundation.h>
#import <LynxServiceAPI/ServiceAPI.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxFastImageServiceProtocol <LynxServiceProtocol>

- (NSString *)name;

@end

@interface LynxFastImageService : NSObject <LynxFastImageServiceProtocol>

@end

NS_ASSUME_NONNULL_END
