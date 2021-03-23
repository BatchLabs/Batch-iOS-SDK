//
//  BAEventTrackedSignal.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAEventTrackedSignal.h>
#import <Batch/BAEventTrigger.h>

@implementation BAEventTrackedSignal

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        self.name = name;
    }
    
    return self;
}

- (BOOL)doesSatisfyTrigger:(nullable id<BALocalCampaignTriggerProtocol>)trigger
{
    if (![trigger isKindOfClass:[BAEventTrigger class]]) {
        return false;
    }
    
    return [((BAEventTrigger*)trigger) isSatisfiedForName:self.name label:nil];
}

@end
