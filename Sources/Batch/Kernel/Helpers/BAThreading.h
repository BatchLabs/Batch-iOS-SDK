//
//  BAThreading.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAThreading : NSObject

+ (void)performBlockOnMainThread:(dispatch_block_t)block;

+ (void)performBlockOnMainThread:(dispatch_block_t)block secondDelay:(NSTimeInterval)delay;

+ (void)performBlockOnMainThreadAsync:(dispatch_block_t)block;

@end
