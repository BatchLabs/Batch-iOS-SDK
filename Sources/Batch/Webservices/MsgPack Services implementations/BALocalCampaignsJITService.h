//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/Batch.h>
#import <Batch/BAWebserviceMsgPackClient.h>
#import <Batch/BALocalCampaignTrackerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BALocalCampaignsJITService : BAWebserviceMsgPackClient <BAConnectionDelegate>

- (nullable instancetype)initWithLocalCampaigns:(nonnull NSArray *)campaigns
                                    viewTracker:(id <BALocalCampaignTrackerProtocol>)viewTracker
                                  success:(void (^ _Nullable)(NSArray* eligibleCampaignIds))successHandler
                                    error:(void (^ _Nullable)(NSError* _Nonnull error, NSNumber* _Nullable retryAfter))errorHandler;

@end

NS_ASSUME_NONNULL_END
