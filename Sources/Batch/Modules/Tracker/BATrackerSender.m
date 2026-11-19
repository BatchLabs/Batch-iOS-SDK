//
//  BATrackerSender.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BALogger.h>
#import <Batch/BAParameter.h>
#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BATrackerSender.h>
#import <Batch/BAWebserviceClientExecutor.h>

#import <Batch/BAEventTrackerService.h>

#import <Batch/BatchUser.h>

#define LOCAL_ERROR_DOMAIN @"Tracker"

@interface BATrackerSender () {
    BOOL _isSending;
    id<BAEventDatasourceProtocol> _datasource;

    // Identifiers of events that the server acknowledged but that could not be deleted from the datasource.
    // Such events must never be sent again, otherwise a datasource that can be read but not written to (full disk,
    // read-only or corrupted database) makes the SDK re-send the same events in a loop as fast as the server answers.
    NSMutableSet<NSString *> *_acknowledgedEventIdentifiers;
}

@end

@implementation BATrackerSender

- (instancetype)init {
    return [self initWithDatasource:nil];
}

- (instancetype)initWithDatasource:(id<BAEventDatasourceProtocol>)datasource {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _isSending = NO;
    _datasource = datasource;
    _acknowledgedEventIdentifiers = [NSMutableSet new];

    return self;
}

- (id<BAEventDatasourceProtocol>)datasource {
    // The tracker center's datasource is resolved lazily: the center creates this sender during its own initialization
    if (_datasource != nil) {
        return _datasource;
    }
    return [BATrackerCenter datasource];
}

- (BOOL)send {
    if (_isSending) {
        return YES;
    }

    id<BAEventDatasourceProtocol> datasource = [self datasource];

    // Clean up acknowledged events before looking for sendable ones: if their state update went through but the
    // deletion failed, they are not sendable anymore and would otherwise only be deleted once new events show up.
    [self retryDeletingAcknowledgedEvents];

    if (![datasource hasEventsToSend]) {
        return NO;
    }

    NSUInteger eventCountToSend =
        [[BAParameter objectForKey:kParametersTrackerWebserviceEventLimitKey
                          fallback:kParametersTrackerWebserviceEventLimitValue] unsignedIntegerValue];

    // Fetch more events than we will send so that acknowledged events still sitting in the datasource don't hide the
    // ones that actually need to be sent. 0 means "all events" and must be left untouched.
    NSUInteger acknowledgedCount = [self acknowledgedEventCount];
    NSUInteger eventCountToFetch = eventCountToSend == 0 ? 0 : eventCountToSend + acknowledgedCount;

    NSArray *events = [datasource eventsToSend:eventCountToFetch];
    events = [self eventsToSendFrom:events limit:eventCountToSend];

    NSArray *eventIDs = [BAEvent identifiersOfEvents:events];

    if ([eventIDs count] == 0) {
        return NO;
    }

    _isSending = YES;

    [datasource updateEventsStateTo:BAEventStateSending forEventsIdentifier:eventIDs];

    BAEventTrackerService *trackerService = [[BAEventTrackerService alloc] initWithEvents:events];
    BAQueryWebserviceClient *ws = [[BAQueryWebserviceClient alloc] initWithDatasource:trackerService
                                                                             delegate:trackerService];
    [BAWebserviceClientExecutor.sharedInstance addClient:ws];

    return YES;
}

- (void)trackingWebserviceDidFinish:(BOOL)success forEvents:(NSArray *)array {
    _isSending = NO;

    if (!array || [array count] == 0) {
        return;
    }

    [[NSNotificationCenter defaultCenter]
        postNotificationName:BatchEventTrackerFinishedNotification
                      object:nil
                    userInfo:@{BatchEventTrackerFinishedWithSuccessKey : [NSNumber numberWithBool:success]}];

    if (success) {
        NSArray *eventIDs = [BAEvent identifiersOfEvents:array];
        if (![[self datasource] deleteEvents:eventIDs]) {
            [BALogger errorForDomain:LOCAL_ERROR_DOMAIN
                             message:@"Could not delete %lu acknowledged events from the datasource: they will not "
                                     @"be sent again during this session.",
                                     (unsigned long)[eventIDs count]];
            @synchronized(_acknowledgedEventIdentifiers) {
                [_acknowledgedEventIdentifiers addObjectsFromArray:eventIDs];
            }
        }
    } else {
        NSMutableArray *oldEvents = [NSMutableArray new];
        NSMutableArray *newEvents = [NSMutableArray new];

        // Split events by status
        for (BAEvent *event in array) {
            if ([event state] == BAEventStateNew) {
                [newEvents addObject:event];
            } else {
                [oldEvents addObject:event];
            }
        }

        [[self datasource] updateEventsStateTo:BAEventStateNew
                           forEventsIdentifier:[BAEvent identifiersOfEvents:newEvents]];
        [[self datasource] updateEventsStateTo:BAEventStateOld
                           forEventsIdentifier:[BAEvent identifiersOfEvents:oldEvents]];
    }
}

#pragma mark -
#pragma mark Acknowledged events handling

- (NSUInteger)acknowledgedEventCount {
    @synchronized(_acknowledgedEventIdentifiers) {
        return [_acknowledgedEventIdentifiers count];
    }
}

// Give the datasource another chance to delete acknowledged events, in case it became writable again
- (void)retryDeletingAcknowledgedEvents {
    NSArray<NSString *> *identifiers;
    @synchronized(_acknowledgedEventIdentifiers) {
        if ([_acknowledgedEventIdentifiers count] == 0) {
            return;
        }
        identifiers = [_acknowledgedEventIdentifiers allObjects];
    }

    if ([[self datasource] deleteEvents:identifiers]) {
        @synchronized(_acknowledgedEventIdentifiers) {
            [_acknowledgedEventIdentifiers minusSet:[NSSet setWithArray:identifiers]];
        }
    }
}

// Filter out acknowledged events and cap the result to the webservice limit (0 meaning no limit)
- (NSArray<BAEvent *> *)eventsToSendFrom:(NSArray<BAEvent *> *)events limit:(NSUInteger)limit {
    @synchronized(_acknowledgedEventIdentifiers) {
        if ([_acknowledgedEventIdentifiers count] == 0) {
            return events;
        }

        NSMutableArray<BAEvent *> *filteredEvents = [NSMutableArray arrayWithCapacity:[events count]];
        for (BAEvent *event in events) {
            if (limit != 0 && [filteredEvents count] >= limit) {
                break;
            }
            if (![_acknowledgedEventIdentifiers containsObject:event.identifier]) {
                [filteredEvents addObject:event];
            }
        }
        return filteredEvents;
    }
}

@end
