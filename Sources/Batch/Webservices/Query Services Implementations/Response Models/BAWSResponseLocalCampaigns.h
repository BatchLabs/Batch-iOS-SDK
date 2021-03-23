//
//  BAWSResponseLocalCampaigns.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSResponse.h>
#import <Batch/BALocalCampaign.h>

/*!
 @class BAWSResponseLocalCampaigns
 @abstract Response of a BAWSResponseLocalCampaigns.
 @discussion Build and serialize the response to the query.
 */
@interface BAWSResponseLocalCampaigns : BAWSResponse <BAWSResponse>

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype _Nullable)init NS_UNAVAILABLE;

@property (nonnull, readonly) NSDictionary *payload;

@end
