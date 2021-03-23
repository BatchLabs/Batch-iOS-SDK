//
//  BAEventTrackerService.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAQueryWebserviceClientDatasource.h>
#import <Batch/BAQueryWebserviceClientDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Event tracker service datasource+delegate
 They are both mixed as the delegate needs data from the datasource
 */
@interface BAEventTrackerService : NSObject <BAQueryWebserviceClientDatasource, BAQueryWebserviceClientDelegate>

- (instancetype)initWithEvents:(NSArray*)events;

/**
 Note that a promise-enabled service will NOT notify the scheduler of success
 */
- (instancetype)initWithEvents:(NSArray*)events promises:(nullable NSArray *)promises;

@end

NS_ASSUME_NONNULL_END
