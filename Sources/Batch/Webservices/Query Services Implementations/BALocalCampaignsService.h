//
//  BALocalCampaignsService.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAQueryWebserviceClientDatasource.h>
#import <Batch/BAQueryWebserviceClientDelegate.h>

#import <Batch/BALocalCampaignCountedEvent.h>

#import <Batch/BALocalCampaignsCenter.h>

NS_ASSUME_NONNULL_BEGIN

@interface BALocalCampaignsServiceDatasource : NSObject <BAQueryWebserviceClientDatasource>

- (instancetype)initWithViewEvents:(nullable NSDictionary<NSString*, BALocalCampaignCountedEvent*>*)viewEvents;

@end

@interface BALocalCampaignsServiceDelegate : NSObject <BAQueryWebserviceClientDelegate>

- (instancetype)initWithLocalCampaignsCenter:(BALocalCampaignsCenter*)center;

@end

NS_ASSUME_NONNULL_END
