//
//  BATWebviewUtils.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BATWebviewUtils : NSObject

// Returns the value of the "batchAnalyticsID" get parameter in an URL if available
+ (nullable NSString*)analyticsIdForURL:(nonnull NSString*)url;

@end

NS_ASSUME_NONNULL_END
