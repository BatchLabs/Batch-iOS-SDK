//
//  BACampaignsRefreshedSignal.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BACampaignsRefreshedSignal.h>

#import <Batch/BANowTrigger.h>
#import <Batch/BACampaignsRefreshedTrigger.h>

@implementation BACampaignsRefreshedSignal

- (BOOL)doesSatisfyTrigger:(nullable id<BALocalCampaignTriggerProtocol>)trigger {
    return [trigger isKindOfClass:[BANowTrigger class]] ||
            [trigger isKindOfClass:[BACampaignsRefreshedTrigger class]];
}

@end
