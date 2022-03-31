//
//  BATaskDebouncer.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BATaskDebouncer.h>

@implementation BATaskDebouncer {
    NSTimeInterval _delayTime;
    dispatch_block_t _taskBlock;
    dispatch_queue_t _queue;
    dispatch_source_t _debounceTimer;
}

+ (instancetype)debouncerWithDelay:(NSTimeInterval)delayTime
                             queue:(dispatch_queue_t)queue
                              task:(dispatch_block_t)taskBlock {
    BATaskDebouncer *debouncer = [BATaskDebouncer new];

    debouncer->_delayTime = delayTime;
    debouncer->_taskBlock = taskBlock;
    debouncer->_queue = queue;

    return debouncer;
}

- (void)schedule {
    dispatch_source_t timer = _debounceTimer;
    _debounceTimer = nil;
    if (timer) {
        dispatch_source_cancel(timer);
    }

    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, _delayTime * NSEC_PER_SEC),
                                  DISPATCH_TIME_FOREVER, 1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, _taskBlock);
        dispatch_resume(timer);
    }
    _debounceTimer = timer;
}

@end
