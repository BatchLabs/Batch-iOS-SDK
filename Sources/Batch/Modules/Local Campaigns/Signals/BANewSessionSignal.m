//
//  BANewSessionSignal.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BANewSessionSignal.h>

#import <Batch/BANextSessionTrigger.h>

@implementation BANewSessionSignal

- (BOOL)doesSatisfyTrigger:(nullable id<BALocalCampaignTriggerProtocol>)trigger {
    return [trigger isKindOfClass:[BANextSessionTrigger class]];
}

@end
