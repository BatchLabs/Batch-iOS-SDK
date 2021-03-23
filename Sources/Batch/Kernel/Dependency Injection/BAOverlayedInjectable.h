//
//  BAOverlayedInjectable.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef _Nullable id (^BAOverlayedInjectableCallback)(_Nullable id originalInstance);

@interface BAOverlayedInjectable : NSObject

/**
 Use BAInjection to get an instance of this object
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
