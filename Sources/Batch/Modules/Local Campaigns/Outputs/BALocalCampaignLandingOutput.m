//
//  BALocalCampaignLandingOutput.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BALocalCampaignLandingOutput.h>

#import <Batch/BAMessagingCenter.h>
#import <Batch/BAThreading.h>
#import <Batch/BatchMessagingPrivate.h>

@implementation BALocalCampaignLandingOutput {
    BatchInAppMessage *_message;
}

- (nullable instancetype)initWithPayload:(nonnull NSDictionary *)payload
                            isCEPMessage:(BOOL)isCEPMessage
                                   error:(NSError **)error {
    self = [super init];
    if (self) {
        // Note: we call an in-app the combination of a landing and a local campaign
        _message = [BatchInAppMessage messageForPayload:payload isCEPMessage:isCEPMessage];

        if (!_message) {
            if (error) {
                *error = [NSError
                    errorWithDomain:@"com.batch.module.localcampaigns.output.landing"
                               code:-10
                           userInfo:@{
                               NSLocalizedDescriptionKey : @"Could not create the underlying BatchInAppMessage "
                                                           @"instance. See debug logs for more info."
                           }];
            }
            return nil;
        }
    }
    return self;
}

- (void)performForCampaign:(nonnull BALocalCampaign *)campaign {
    BatchInAppMessage *msg = [_message copy];
    [msg setCampaign:campaign];

    [BAThreading
        performBlockOnMainThread:^{
          [[BAMessagingCenter instance] handleInAppMessage:msg];
        }
                     secondDelay:campaign.displayDelaySec];
}

@end
