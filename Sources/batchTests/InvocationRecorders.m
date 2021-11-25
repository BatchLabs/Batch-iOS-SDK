#import "InvocationRecorders.h"

@implementation InvocationRecordingProxy
{
    id _proxiedObject;
    NSMutableSet<NSString*> *_mutableInvokedSelectors;
}

+ (instancetype)proxyWithObject:(id)object {
    return [[InvocationRecordingProxy alloc] proxy_initWithObject:object];
}

- (instancetype)proxy_initWithObject:(id)object
{
    _proxiedObject = object;
    _mutableInvokedSelectors = [[NSMutableSet alloc] init];
    return self;
}

- (NSSet<NSString*>*)proxy_invokedSelectors {
    return [_mutableInvokedSelectors copy];
}

- (void)proxy_recordSelector:(SEL)selector {
    [_mutableInvokedSelectors addObject:NSStringFromSelector(selector)];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [_proxiedObject methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [self proxy_recordSelector:anInvocation.selector];
    [anInvocation setTarget:_proxiedObject];
    [anInvocation invoke];
    return;
}

@end

// Same as InvocationRecordingProxy but when you can't use an NSProxy
// (usually only because of swizzling)
// Methods must be recorded manually
@implementation InvocationRecordingObject
{
    NSMutableSet<NSString*> *_mutableInvokedSelectors;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableInvokedSelectors = [[NSMutableSet alloc] init];
    }
    return self;
}

- (NSSet<NSString*>*)invokedSelectors {
    return [_mutableInvokedSelectors copy];
}

- (void)recordSelector:(SEL)selector {
    [_mutableInvokedSelectors addObject:NSStringFromSelector(selector)];
}

@end
