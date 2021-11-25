//
//  BATrackerSender.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BATrackerSender.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BAWebserviceClientExecutor.h>
#import <Batch/BAParameter.h>

#import <Batch/BAEventTrackerService.h>

#import <Batch/BatchUser.h>

@interface BATrackerSender ()
{
    BOOL _isSending;
}

@end


@implementation BATrackerSender

- (instancetype)init
{
    self = [super init];
    if (self == nil)
    {
        return nil;
    }
    
    _isSending = NO;
    
    return self;
}

- (BOOL)send
{
    if ([BATrackerCenter currentMode] != BATrackerModeON)
    {
        // Nothing to do, not send.
        return NO;
    }

    if (_isSending)
    {
        return YES;
    }
    
    if (![[BATrackerCenter datasource] hasEventsToSend])
    {
        return NO;
    }
    
    NSUInteger eventCountToSend = [[BAParameter objectForKey:kParametersTrackerWebserviceEventLimitKey fallback:kParametersTrackerWebserviceEventLimitValue] unsignedIntegerValue];
    NSArray *events = [[BATrackerCenter datasource] eventsToSend:eventCountToSend];
    
    NSArray *eventIDs = [BAEvent identifiersOfEvents:events];
    
    if ([eventIDs count] == 0)
    {
        return NO;
    }
    
    _isSending = YES;
    
    [[BATrackerCenter datasource] updateEventsStateTo:BAEventStateSending forEventsIdentifier:eventIDs];
    
    BAEventTrackerService *trackerService = [[BAEventTrackerService alloc] initWithEvents:events];
    BAQueryWebserviceClient *ws = [[BAQueryWebserviceClient alloc] initWithDatasource:trackerService
                                                                             delegate:trackerService];
    [BAWebserviceClientExecutor.sharedInstance addClient:ws];
    
    return YES;
}

- (void)trackingWebserviceDidFinish:(BOOL)success forEvents:(NSArray *)array
{
    _isSending = NO;
    
    if (!array || [array count] == 0)
    {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BatchEventTrackerFinishedNotification
                                                        object:nil
                                                      userInfo:@{BatchEventTrackerFinishedWithSuccessKey: [NSNumber numberWithBool:success]}];
    
    if (success)
    {
        NSArray *eventIDs = [BAEvent identifiersOfEvents:array];
        [[BATrackerCenter datasource] deleteEvents:eventIDs];
    }
    else
    {
        NSMutableArray *oldEvents = [NSMutableArray new];
        NSMutableArray *newEvents = [NSMutableArray new];
        
        // Split events by status
        for (BAEvent *event in array)
        {
            if( [event state] == BAEventStateNew )
            {
                [newEvents addObject:event];
            }
            else
            {
                [oldEvents addObject:event];
            }
        }

        [[BATrackerCenter datasource] updateEventsStateTo:BAEventStateNew forEventsIdentifier:[BAEvent identifiersOfEvents:newEvents]];
        [[BATrackerCenter datasource] updateEventsStateTo:BAEventStateOld forEventsIdentifier:[BAEvent identifiersOfEvents:oldEvents]];
    }
}

@end
