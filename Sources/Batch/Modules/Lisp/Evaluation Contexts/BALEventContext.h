//
//  BALEventContext.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Batch/BALEvaluationContext.h>

NS_ASSUME_NONNULL_BEGIN

@class BatchEventData;

@interface BALEventContext : NSObject <BALEvaluationContext>

+ (instancetype)contextWithPrivateEvent:(NSString*)name;

+ (instancetype)contextWithPublicEvent:(NSString*)name label:(nullable NSString*)label data:(nullable BatchEventData*)data;

@end

NS_ASSUME_NONNULL_END
