//
//  BAOptOutWebserviceClient.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAOptOutWebserviceClient.h>

#import <Batch/BAEventTrackerService.h>

@implementation BAOptOutWebserviceClient

- (instancetype)initWithEvents:(NSArray *)events promises:(NSArray *)promises {
    BAEventTrackerService *service = [[BAEventTrackerService alloc] initWithEvents:events promises:promises];
    return [super initWithDatasource:service delegate:service];
}

- (BOOL)canBypassOptOut {
    return true;
}

@end
