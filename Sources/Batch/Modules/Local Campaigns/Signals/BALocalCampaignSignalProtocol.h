//
//  BALocalCampaignSignalProtocol.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignTriggerProtocol.h>

/**
 Represents an signal

 A signal is anything that happens during the lifecycle of an app that
 can trigger a local campaign
 */
@protocol BALocalCampaignSignalProtocol <NSObject>

@required

- (BOOL)doesSatisfyTrigger:(nullable id<BALocalCampaignTriggerProtocol>)trigger;

@end
