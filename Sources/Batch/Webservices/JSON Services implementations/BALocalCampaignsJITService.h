//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BALocalCampaignTrackerProtocol.h>
#import <Batch/BALocalCampaignsVersion.h>
#import <Batch/BAWebserviceJsonClient.h>
#import <Batch/Batch.h>

NS_ASSUME_NONNULL_BEGIN

@interface BALocalCampaignsJITService : BAWebserviceJsonClient <BAConnectionDelegate>

- (nullable instancetype)initWithLocalCampaigns:(nonnull NSArray *)campaigns
                                    viewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker
                                        version:(BALocalCampaignsVersion)version
                                        success:(void (^_Nullable)(NSArray *eligibleCampaignIds))successHandler
                                          error:(void (^_Nullable)(NSError *_Nonnull error,
                                                                   NSNumber *_Nullable retryAfter))errorHandler;

@end

NS_ASSUME_NONNULL_END
