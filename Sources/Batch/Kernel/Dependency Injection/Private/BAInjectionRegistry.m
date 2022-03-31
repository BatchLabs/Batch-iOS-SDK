//
//  BAInjectionRegistry.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInjectionRegistrar.h>
#import <Batch/BAInjectionRegistry.h>

@interface BAInjectionRegistry () {
    NSMapTable<Class, BAInjectable *> *_classInjectables;
    NSMapTable<Protocol *, BAInjectable *> *_protocolInjectables;

    NSMapTable<id, BAOverlayedInjectable *> *_overlaysTable;

    NSObject *_registrationLockToken;
    NSObject *_overlaysLockToken;
}
@end

@implementation BAInjectionRegistry

#pragma mark Public methods

+ (instancetype)sharedInstance {
    static BAInjectionRegistry *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [BAInjectionRegistry new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _classInjectables = [NSMapTable strongToStrongObjectsMapTable];
        _protocolInjectables = [NSMapTable strongToStrongObjectsMapTable];
        _overlaysTable = nil;
        _registrationLockToken = [NSObject new];
        _overlaysLockToken = [NSObject new];
    }
    return self;
}

#pragma mark Injectable registration

- (void)registerInjectable:(nonnull BAInjectable *)injectable forClass:(nonnull Class)classToRegister {
    @synchronized(_registrationLockToken) {
        NSMapTable<Class, BAInjectable *> *newInjectables = [_classInjectables copy];
        [newInjectables setObject:injectable forKey:classToRegister];
        _classInjectables = newInjectables;
    }
}

- (void)registerInjectable:(nonnull BAInjectable *)injectable forProtocol:(nonnull Protocol *)protocol {
    @synchronized(_registrationLockToken) {
        NSMapTable<Protocol *, BAInjectable *> *newInjectables = [_protocolInjectables copy];
        [newInjectables setObject:injectable forKey:protocol];
        _protocolInjectables = newInjectables;
    }
}

#pragma mark Injection

- (nullable id)injectClass:(Class _Nonnull)classToInject {
    [self registerInjectablesIfNeeded];
    id instance = [[_classInjectables objectForKey:classToInject] resolveInstance];
    if (_overlaysTable != nil) {
        return [self overlayedClass:classToInject originalInstance:instance];
    }
    return instance;
}

- (nullable id)injectProtocol:(nonnull Protocol *)protocolToInject {
    [self registerInjectablesIfNeeded];
    id instance = [[_protocolInjectables objectForKey:protocolToInject] resolveInstance];
    if (_overlaysTable != nil) {
        return [self overlayedProtocol:protocolToInject originalInstance:instance];
    }
    return instance;
}

#pragma mark Registration

- (void)registerInjectablesIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      [BAInjectionRegistrar registerInjectables];
    });
}

#pragma mark Overlaying

- (nonnull BAOverlayedInjectable *)overlayProtocol:(nonnull Protocol *)protocol
                                          callback:(nonnull BAOverlayedInjectableCallback)callback {
    BAOverlayedInjectable *overlay = [[BAOverlayedInjectable alloc] initWithCallback:callback];
    [self setOverlay:overlay forKey:protocol];
    return overlay;
}

- (nonnull BAOverlayedInjectable *)overlayProtocol:(nonnull Protocol *)protocol
                                  returnedInstance:(nullable id)instanceToReturn {
    return [self overlayProtocol:protocol
                        callback:^id _Nullable(id _Nullable originalInstance) {
                          return instanceToReturn;
                        }];
}

- (nonnull BAOverlayedInjectable *)overlayClass:(Class _Nonnull)classToOverlay
                                       callback:(nonnull BAOverlayedInjectableCallback)callback {
    BAOverlayedInjectable *overlay = [[BAOverlayedInjectable alloc] initWithCallback:callback];
    [self setOverlay:overlay forKey:classToOverlay];
    return overlay;
}

- (nonnull BAOverlayedInjectable *)overlayClass:(Class _Nonnull)classToOverlay
                               returnedInstance:(nullable id)instanceToReturn {
    return [self overlayClass:classToOverlay
                     callback:^id _Nullable(id _Nullable originalInstance) {
                       return instanceToReturn;
                     }];
}

- (void)unregisterOverlay:(nonnull BAOverlayedInjectable *)overlay {
    @synchronized(_overlaysLockToken) {
        if (_overlaysTable != nil) {
            @synchronized(_overlaysTable) {
                NSMapTable<id, BAOverlayedInjectable *> *overlaysTableCopy = [_overlaysTable copy];

                for (id key in overlaysTableCopy.keyEnumerator) {
                    if ([_overlaysTable objectForKey:key] == overlay) {
                        [_overlaysTable removeObjectForKey:key];
                    }
                }
            }
        }
    }
}

#pragma mark -

#pragma mark Overlaying - Internal

- (void)setupOverlay {
    @synchronized(_overlaysLockToken) {
        if (_overlaysTable == nil) {
            _overlaysTable = [NSMapTable strongToWeakObjectsMapTable];
        }
    }
}

- (id)overlayedProtocol:(Protocol *)protocolToInject originalInstance:(id)originalInstance {
    @synchronized(_overlaysTable) {
        BAOverlayedInjectable *overlay = [_overlaysTable objectForKey:protocolToInject];
        if (overlay != nil) {
            return [overlay resolveWithOriginalInstance:originalInstance];
        }
        return originalInstance;
    }
}

- (id)overlayedClass:(Class)classToInject originalInstance:(id)originalInstance {
    @synchronized(_overlaysTable) {
        BAOverlayedInjectable *overlay = [_overlaysTable objectForKey:classToInject];
        if (overlay != nil) {
            return [overlay resolveWithOriginalInstance:originalInstance];
        }
        return originalInstance;
    }
}

- (void)setOverlay:(BAOverlayedInjectable *)overlay forKey:(nonnull id)key {
    [self setupOverlay];
    @synchronized(_overlaysTable) {
        [_overlaysTable setObject:overlay forKey:key];
    }
}

@end
