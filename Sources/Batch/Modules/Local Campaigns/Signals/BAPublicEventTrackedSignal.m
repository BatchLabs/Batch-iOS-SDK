//
//  BAPublicEventTrackedSignal.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAPublicEventTrackedSignal.h>
#import <Batch/BAEventTrigger.h>

@implementation BAPublicEventTrackedSignal

- (instancetype)initWithName:(NSString *)name label:(nullable NSString *)label data:(nullable BatchEventData *)data
{
    self = [super init];
    if (self) {
        self.name = name;
        self.label = label;
        self.data = data;
    }

    return self;
}

- (BOOL)doesSatisfyTrigger:(nullable id<BALocalCampaignTriggerProtocol>)trigger
{
    if (![trigger isKindOfClass:[BAEventTrigger class]]) {
        return false;
    }

    return [((BAEventTrigger*)trigger) isSatisfiedForName:self.name label: self.label];
}

@end
