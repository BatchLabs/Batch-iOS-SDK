//
//  BACampaignsLoadedSignal.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BACampaignsLoadedSignal.h>

#import <Batch/BANowTrigger.h>
#import <Batch/BACampaignsLoadedTrigger.h>
#import <Batch/BANextSessionTrigger.h>

@implementation BACampaignsLoadedSignal

- (BOOL)doesSatisfyTrigger:(nullable id<BALocalCampaignTriggerProtocol>)trigger {
    return [trigger isKindOfClass:[BANowTrigger class]] ||
            [trigger isKindOfClass:[BACampaignsLoadedTrigger class]];
}

@end
