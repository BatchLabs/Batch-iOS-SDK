//
//  BAOptOutWebserviceClient.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAQueryWebserviceClient.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Subclass of BAQueryWebserviceClient for the opted-out event tracker.
 It bypasses the opt-out, allowing server communication for this very specific and desirable case
 */
@interface BAOptOutWebserviceClient : BAQueryWebserviceClient

- (instancetype)initWithEvents:(NSArray*)events promises:(NSArray *)promises;

@end

NS_ASSUME_NONNULL_END
