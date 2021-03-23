//
//  BAInjectable.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInjectable.h>

#import <Batch/BAInjectableImplementations.h>

@implementation BAInjectable

#pragma mark Classes

+ (nonnull BAInjectable*)injectableWithInitializer:(nonnull BAInjectableInitializer)initializer
{
    return [[BABlockInitializerInjectable alloc] initWithInitializer:initializer];
}

+ (nonnull BAInjectable*)injectableWithInstance:(nullable id)instance
{
    return [[BAInstanceInjectable alloc] initWithInstance:instance];
}

#pragma mark Instance resolving

- (id)resolveInstance
{
    return nil;
}

#pragma mark Other

- (NSString*)description
{
    return @"BAInjectable";
}

@end
