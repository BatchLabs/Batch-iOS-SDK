//
//  BAInjectionRegistry.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAInjectable.h>
#import <Batch/BAOverlayedInjectable.h>
#import <Batch/BAOverlayedInjectable-Private.h>

@interface BAInjectionRegistry : NSObject

+ (nonnull instancetype)sharedInstance;

- (void)registerInjectable:(nonnull BAInjectable*)injectable
               forProtocol:(nonnull Protocol*)protocol
NS_SWIFT_NAME(register(injectable:forProtocol:));

- (void)registerInjectable:(nonnull BAInjectable*)injectable
                  forClass:(nonnull Class)classToRegister
NS_SWIFT_NAME(register(injectable:forClass:));

// Overlays

- (nonnull BAOverlayedInjectable*)overlayProtocol:(nonnull Protocol*)protocol
                                         callback:(nonnull BAOverlayedInjectableCallback)callback;

- (nonnull BAOverlayedInjectable*)overlayProtocol:(nonnull Protocol*)protocol
                                 returnedInstance:(nullable id)instanceToReturn;

- (nonnull BAOverlayedInjectable*)overlayClass:(Class _Nonnull)classToOverlay
                                      callback:(nonnull BAOverlayedInjectableCallback)callback;

- (nonnull BAOverlayedInjectable*)overlayClass:(Class _Nonnull)classToOverlay
                              returnedInstance:(nullable id)instanceToReturn;

- (void)unregisterOverlay:(nonnull BAOverlayedInjectable*)overlay;

// Injection methods
// We need to differentiate them in Swift, else the protocol will end in "injectClass" and that's a crash!

- (nullable id)injectClass:(Class _Nonnull)classToInject NS_SWIFT_NAME(inject(class:));

- (nullable id)injectProtocol:(nonnull Protocol*)protocolToInject NS_SWIFT_NAME(inject(protocol:));

@end
