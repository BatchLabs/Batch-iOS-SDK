//
//  BAInjectable.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef _Nullable id (^BAInjectableInitializer)(void);

@interface BAInjectable : NSObject

/**
 Make an injectable using an initializer block. The initializer will be called on each injection.
 */
+ (nonnull BAInjectable *)injectableWithInitializer:(nonnull BAInjectableInitializer)initializer;

/**
Make an injectable for an instance. The given instance will be returned directly.
*/
+ (nonnull BAInjectable *)injectableWithInstance:(nullable id)instance;

/**
 Resolve the instance
 */
- (nullable id)resolveInstance;

@end
