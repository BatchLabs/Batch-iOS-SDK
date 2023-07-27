//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BADateProviderProtocol.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAMutableDateProvider : NSObject <BADateProviderProtocol>

- (instancetype)initWithTimestamp:(double)timestamp;

- (void)setTime:(double)timestamp;

@end

NS_ASSUME_NONNULL_END
