//
//  BATaskDebouncer.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Allows deboucing of a task defined by a block.

 Warning: Calling "shedule" in between threads isn't supported.
 */
@interface BATaskDebouncer : NSObject

+ (instancetype)debouncerWithDelay:(NSTimeInterval)delayTime
                             queue:(dispatch_queue_t)queue
                              task:(dispatch_block_t)taskBlock;

- (void)schedule;

@end
