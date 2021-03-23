//
//  BAInjectableImplementations.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAInjectable.h>

/**
 A BAInjectable that simply returns a value
 */
@interface BAInstanceInjectable : BAInjectable

- (nonnull instancetype)initWithInstance:(nullable id)instance;

@end

/**
 A BAInjectable that uses a block to return a value
 */
@interface BABlockInitializerInjectable : BAInjectable

- (nonnull instancetype)initWithInitializer:(nonnull BAInjectableInitializer)initializer;

@end
