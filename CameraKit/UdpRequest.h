#import <Foundation/Foundation.h>

typedef void (^CompletionBlock)(NSString *ddUrl, NSArray *uuid);

@interface UdpRequest : NSObject

- (void)execute:(CompletionBlock)block;
- (void)stop;
@end
