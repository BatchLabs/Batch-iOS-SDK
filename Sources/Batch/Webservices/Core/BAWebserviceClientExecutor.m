//
//  BAWebserviceClientExecutor.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWebserviceClientExecutor.h>

@interface BAWebserviceClientExecutor ()
{
    NSOperationQueue *_queue;
}
@end

@implementation BAWebserviceClientExecutor

+ (BAWebserviceClientExecutor *)sharedInstance
{
    static BAWebserviceClientExecutor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BAWebserviceClientExecutor new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = kWebserviceClientExecutorMaxConcurrency;
    }
    return self;
}

- (void)addClient:(BAWebserviceClient*)client
{
    [_queue addOperation:client];
}

@end
