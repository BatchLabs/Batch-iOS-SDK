//
//  BALocalCampaignsParser.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaign.h>
#import <Batch/BAEventTrigger.h>

NS_ASSUME_NONNULL_BEGIN

@interface BALocalCampaignsParser : NSObject

+ (nullable NSArray<BALocalCampaign*>*)parseCampaigns:(nonnull NSDictionary*)rawJson outPersistable:(NSDictionary * _Nullable * _Nullable)persist error:(NSError**)error;

+ (nullable BALocalCampaign*)parseCampaign:(nonnull NSDictionary*)rawJson error:(NSError**)error;

+ (nullable id<BALocalCampaignTriggerProtocol>)parseTrigger:(nonnull NSDictionary*)rawJson error:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
