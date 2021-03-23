//
//  BAOverlayedInjectable.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAOverlayedInjectable.h>
#import <Batch/BAOverlayedInjectable-Private.h>

@implementation BAOverlayedInjectable
{
    BAOverlayedInjectableCallback _callback;
}

- (nonnull instancetype)initWithCallback:(nonnull BAOverlayedInjectableCallback)callback
{
    self = [super init];
    if (self) {
        _callback = callback;
    }
    return self;
}

- (nullable id)resolveWithOriginalInstance:(nullable id)originalInstance
{
    return _callback(originalInstance);
}

@end
