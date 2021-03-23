//
//  BAInjection.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAInjectable.h>
#import <Batch/BAOverlayedInjectable.h>

// Helper macro to make a static c function ran on library load
#define bainjection_injectable_initializer __attribute((constructor)) static void

#define bainjection_instance_singleton(initializer) \
static id instance = nil; \
static dispatch_once_t once; \
dispatch_once(&once, ^{ \
  instance = initializer; \
}); \
return instance;

// Annotation that indicates that methods should be injected rather than initialized unless we're in a test case
#define BATCH_USE_INJECTION_OUTSIDE_TESTS  

/**
 Handles dependency injection for Batch
 
 This class manages injectables, acts as a registry for them, initializes them, ...
 It also supports overlaying them for tests
 */
@interface BAInjection : NSObject

// Registry interaction

+ (void)registerInjectable:(nonnull BAInjectable*)injectable
               forProtocol:(nonnull Protocol*)protocol;

+ (void)registerInjectable:(nonnull BAInjectable*)injectable
                  forClass:(nonnull Class)classToRegister;

// Overlays

+ (nonnull BAOverlayedInjectable*)overlayProtocol:(nonnull Protocol*)protocol
                                         callback:(nonnull BAOverlayedInjectableCallback)callback;

+ (nonnull BAOverlayedInjectable*)overlayProtocol:(nonnull Protocol*)protocol
                                 returnedInstance:(nullable id)instanceToReturn;

+ (nonnull BAOverlayedInjectable*)overlayClass:(Class _Nonnull)classToOverlay
                                      callback:(nonnull BAOverlayedInjectableCallback)callback;

+ (nonnull BAOverlayedInjectable*)overlayClass:(Class _Nonnull)classToOverlay
                              returnedInstance:(nullable id)instanceToReturn;

+ (void)unregisterOverlay:(nonnull BAOverlayedInjectable*)overlay;

// Injection methods

+ (nullable id)injectClass:(Class _Nonnull)classToInject;

+ (nullable id)injectProtocol:(nonnull Protocol*)protocolToInject;

@end
