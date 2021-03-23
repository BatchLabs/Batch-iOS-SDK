//
//  BALocalCampaignsPersisting.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol BALocalCampaignsPersisting

@required

- (void)persistCampaigns:(nonnull NSDictionary*)rawCampaignsData;

- (nullable NSDictionary*)loadCampaignsWithError:(NSError**)error;

- (void)deleteCampaigns;

@end

NS_ASSUME_NONNULL_END
