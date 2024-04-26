//
//  BAPublicEventTrackedSignal.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAEventTrigger.h>
#import <Batch/BAPublicEventTrackedSignal.h>

@implementation BAPublicEventTrackedSignal

- (instancetype)initWithName:(NSString *)name
                       label:(nullable NSString *)label
                  attributes:(nullable BatchEventAttributes *)attributes {
    self = [super init];
    if (self) {
        self.name = name;
        self.label = label;
        self.attributes = attributes;
    }

    return self;
}

- (BOOL)doesSatisfyTrigger:(nullable id<BALocalCampaignTriggerProtocol>)trigger {
    if (![trigger isKindOfClass:[BAEventTrigger class]]) {
        return false;
    }

    return [((BAEventTrigger *)trigger) isSatisfiedForName:self.name label:self.label];
}

@end
