//
//  BAOverlayedInjectable-Private.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

@interface BAOverlayedInjectable()

- (nonnull instancetype)initWithCallback:(nonnull BAOverlayedInjectableCallback)callback;

- (nullable id)resolveWithOriginalInstance:(nullable id)originalInstance;

@end
