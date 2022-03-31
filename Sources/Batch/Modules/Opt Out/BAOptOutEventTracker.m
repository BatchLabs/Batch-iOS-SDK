//
//  BAOptOutEventTracker.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAOptOutEventTracker.h>

#import <Batch/BAConcurrentQueue.h>
#import <Batch/BAOptOutWebserviceClient.h>
#import <Batch/BATaskDebouncer.h>
#import <Batch/BAWebserviceClientExecutor.h>

#define DEBOUNCE_DELAY_SEC 1

@interface BAPromisedEvent : NSObject

@property (strong, nonatomic) BAPromise *promise;
@property (strong, nonatomic) BAEvent *event;

@end

@implementation BAOptOutEventTracker {
    BAConcurrentQueue *_memoryQueue;
    BATaskDebouncer *_flushDebouncer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _memoryQueue = [BAConcurrentQueue new];
        _flushDebouncer = [BATaskDebouncer debouncerWithDelay:DEBOUNCE_DELAY_SEC
                                                        queue:dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                                                         task:^{
                                                           [self flush];
                                                         }];
    }
    return self;
}

- (BAPromise *)track:(BAEvent *)event;
{
    BAPromise *promise = [BAPromise new];
    BAPromisedEvent *promisedEvent = [BAPromisedEvent new];
    promisedEvent.promise = promise;
    promisedEvent.event = event;
    [_memoryQueue push:promisedEvent];

    [_flushDebouncer schedule];

    return promise;
}

- (void)flush {
    NSArray *queue = [_memoryQueue pollAll];

    NSMutableArray *events = [NSMutableArray arrayWithCapacity:queue.count];
    NSMutableArray *promises = [NSMutableArray arrayWithCapacity:queue.count];

    for (BAPromisedEvent *event in queue) {
        [events addObject:event.event];
        [promises addObject:event.promise];
    }

    [BAWebserviceClientExecutor.sharedInstance addClient:[[BAOptOutWebserviceClient alloc] initWithEvents:events
                                                                                                 promises:promises]];
}

@end

@implementation BAPromisedEvent

@end
