//
//  BALocalCampaign.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BALocalCampaign.h>

@implementation BALocalCampaign

- (void)generateOccurrenceIdentifier
{
    NSMutableDictionary *mutableEventData;
    if (self.eventData != nil) {
        mutableEventData = [[NSMutableDictionary alloc] initWithDictionary:self.eventData];
    } else {
        mutableEventData = [[NSMutableDictionary alloc] initWithCapacity:1];
    }
    
    mutableEventData[@"i"] = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]*1000];
    
    self.eventData = mutableEventData;
}

@end
