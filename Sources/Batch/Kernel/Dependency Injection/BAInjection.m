//
//  BAInjection.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInjection.h>

#import <Batch/BAInjectionRegistry.h>

@implementation BAInjection

+ (void)registerInjectable:(nonnull BAInjectable*)injectable
               forProtocol:(nonnull Protocol*)protocol
{
    [[BAInjectionRegistry sharedInstance]registerInjectable:injectable forProtocol:protocol];
}

+ (void)registerInjectable:(nonnull BAInjectable*)injectable
                  forClass:(nonnull Class)classToRegister
{
    [[BAInjectionRegistry sharedInstance] registerInjectable:injectable forClass:classToRegister];
}

#pragma mark Injection

+ (nullable id)injectClass:(Class _Nonnull)classToInject
{
    return [[BAInjectionRegistry sharedInstance] injectClass:classToInject];
}

+ (nullable id)injectProtocol:(nonnull Protocol *)protocolToInject
{
    return [[BAInjectionRegistry sharedInstance] injectProtocol:protocolToInject];
}

#pragma mark Overlaying

+ (nonnull BAOverlayedInjectable *)overlayProtocol:(nonnull Protocol *)protocol
                                          callback:(nonnull BAOverlayedInjectableCallback)callback
{
    return [[BAInjectionRegistry sharedInstance] overlayProtocol:protocol
                                                        callback:callback];
}

+ (nonnull BAOverlayedInjectable *)overlayProtocol:(nonnull Protocol *)protocol
                                  returnedInstance:(nullable id)instanceToReturn
{
    return [[BAInjectionRegistry sharedInstance] overlayProtocol:protocol
                                                returnedInstance:instanceToReturn];
}

+ (nonnull BAOverlayedInjectable *)overlayClass:(Class _Nonnull)classToOverlay
                                       callback:(nonnull BAOverlayedInjectableCallback)callback
{
    return [[BAInjectionRegistry sharedInstance] overlayClass:classToOverlay
                                                     callback:callback];
}

+ (nonnull BAOverlayedInjectable *)overlayClass:(Class _Nonnull)classToOverlay
                               returnedInstance:(nullable id)instanceToReturn
{
    return [[BAInjectionRegistry sharedInstance] overlayClass:classToOverlay
                                             returnedInstance:instanceToReturn];
}

+ (void)unregisterOverlay:(nonnull BAOverlayedInjectable*)overlay
{
    [[BAInjectionRegistry sharedInstance] unregisterOverlay:overlay];
}

@end
