//
//  BALocalCampaignOutputProtocol.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignTriggerProtocol.h>

@class BALocalCampaign;

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a local campaign output

 An output is the action executed by a triggered local campaign
 */
@protocol BALocalCampaignOutputProtocol <NSObject>

@required

- (nullable instancetype)initWithPayload:(nonnull NSDictionary *)payload error:(NSError **)error;

- (void)performForCampaign:(nonnull BALocalCampaign *)campaign;

@end

NS_ASSUME_NONNULL_END
