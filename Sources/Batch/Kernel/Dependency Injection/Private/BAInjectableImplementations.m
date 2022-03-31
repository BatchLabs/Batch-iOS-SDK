//
//  BAInjectableImplementations.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInjectableImplementations.h>

/**
 BAInjectable class cluster
 */

@implementation BAInstanceInjectable {
    id _instance;
}

- (nonnull instancetype)initWithInstance:(id)instance {
    self = [super init];
    if (self) {
        _instance = instance;
    }
    return self;
}

- (id)resolveInstance {
    return _instance;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BAInjectable - Instance: %@", _instance];
}

@end

@implementation BABlockInitializerInjectable {
    BAInjectableInitializer _initializer;
}

- (nonnull instancetype)initWithInitializer:(nonnull BAInjectableInitializer)initializer {
    self = [super init];
    if (self) {
        _initializer = initializer;
    }
    return self;
}

- (id)resolveInstance {
    return _initializer();
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BAInjectable - Initializer block: %@", _initializer];
}

@end
