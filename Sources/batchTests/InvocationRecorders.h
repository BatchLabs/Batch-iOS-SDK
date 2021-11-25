#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Proxy that records all messages that are sent to it
@interface InvocationRecordingProxy : NSProxy

+ (instancetype)proxyWithObject:(id)object;

@property (readonly) NSSet<NSString*>* proxy_invokedSelectors;

@end

// Same as InvocationRecordingProxy but when you can't use an NSProxy
// (usually only because of swizzling)
// Methods must be recorded manually
@interface InvocationRecordingObject : NSObject

@property (readonly) NSSet<NSString*>* invokedSelectors;

- (void)recordSelector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
