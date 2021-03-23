//
//  BAThreading.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BAThreading.h>

@implementation BAThreading

+ (void)performBlockOnMainThread:(dispatch_block_t)block
{
    if (block == nil)
    {
        return;
    }
    
    if ([NSThread currentThread].isMainThread)
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)performBlockOnMainThread:(dispatch_block_t)block secondDelay:(NSTimeInterval)delay
{
    if (block == nil) {
        return;
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

+ (void)performBlockOnMainThreadAsync:(dispatch_block_t)block
{
    if (block == nil)
    {
        return;
    }

    if ([NSThread currentThread].isMainThread)
    {
        block();
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@end
