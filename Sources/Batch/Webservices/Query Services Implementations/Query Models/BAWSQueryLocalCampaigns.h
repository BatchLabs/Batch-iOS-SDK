//
//  BAWSQueryLocalCampaigns.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWSQuery.h>
#import <Batch/BALocalCampaignCountedEvent.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class BAWSQueryLocalCampaigns
 @abstract Query requesting for local campaigns
 */
@interface BAWSQueryLocalCampaigns : BAWSQuery <BAWSQuery>

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @abstract Standard constructor.
 @param viewEvents : Array of viewEvents to forward to the server
 @return Instance or nil.
 */
- (instancetype)initWithViewEvents:(nullable NSDictionary<NSString*, BALocalCampaignCountedEvent*>*)viewEvents;

@end

NS_ASSUME_NONNULL_END
