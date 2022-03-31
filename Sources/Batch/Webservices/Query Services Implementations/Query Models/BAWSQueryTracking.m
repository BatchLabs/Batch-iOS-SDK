//
//  BAWebserviceQueryTracking.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSQueryTracking.h>

#import <Batch/BAEvent.h>
#import <Batch/BAJson.h>

@interface BAWSQueryTracking ()
{
    // Events to send
    NSArray        *_events;
}
@end

@implementation BAWSQueryTracking

// Standard constructor.
- (instancetype)initWithEvents:(nonnull NSArray *)events
{
    self = [super initWithType:kQueryWebserviceTypeTracking];
    if (self) {
        _events = events;
    }
    
    return self;
}

// Build the basic object to send to the server as a query.
- (NSMutableDictionary *)objectToSend
{
    NSMutableDictionary *dictionary = [super objectToSend];
    
    NSMutableArray *oldEvents = [NSMutableArray new];
    NSMutableArray *newEvents = [NSMutableArray new];
    
    // Serialize events and split them by status
    for (BAEvent *event in _events)
    {
        NSMutableDictionary *eventDict = [NSMutableDictionary dictionaryWithDictionary:@{@"id": [event identifier],
                                                                                         @"date": [event date],
                                                                                         @"name": [event name],
                                                                                         @"ts": @([event tick])}];
        
        if ([event session] != nil)
        {
            [eventDict setObject:event.session forKey:@"session"];
        }
        
        if ([event parameters] != nil)
        {          
            NSDictionary *jsonParameters = [BAJson deserializeAsDictionary:[event parameters] error:nil];
            if (jsonParameters != nil) {
                [eventDict setObject:jsonParameters forKey:@"params"];
            }
        }
        
        if ([event secureDate] != nil)
        {
            [eventDict setObject:event.secureDate forKey:@"sDate"];
        }
        
        if( [event state] == BAEventStateNew )
        {
            [newEvents addObject:eventDict];
        }
        else
        {
            [oldEvents addObject:eventDict];
        }
    }
    
    NSMutableDictionary *eventsQueryDict = [NSMutableDictionary new];
    
    if ([oldEvents count] > 0)
    {
        [eventsQueryDict setObject:oldEvents forKey:@"old"];
    }
    if ([newEvents count] > 0)
    {
        [eventsQueryDict setObject:newEvents forKey:@"new"];
    }
    
    [dictionary setValue:eventsQueryDict forKey:kWebserviceKeyQueryEvents];
    
    return dictionary;
}

@end
