//  https://batch.com
//  Copyright (c) 2018 Batch SDK. All rights reserved.

#import <Batch/BAPromise.h>

/**
 A simple Promise-like implementation that can only be resolved and is not thread-safe.
 then can't mutate the value
 catch does not exist
 */
@implementation BAPromise
{
    BAPromiseStatus _status;
    NSObject *_resolvedValue; // NSError* if rejected
    NSMutableArray *_thenQueue;
    void (^_catchBlock)(NSError*);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _status = BAPromiseStatusPending;
        _resolvedValue = nil;
        _thenQueue = [NSMutableArray new];
    }
    return self;
}

+ (nonnull instancetype)resolved:(nullable NSObject*)value
{
    BAPromise *promise = [BAPromise new];
    [promise resolve:value];
    return promise;
}

+ (nonnull instancetype)rejected:(nullable NSError*)error
{
    BAPromise *promise = [BAPromise new];
    [promise reject:error];
    return promise;
}

- (void)resolve:(nullable NSObject*)value
{
    @synchronized(_thenQueue) {
        if (_status != BAPromiseStatusPending) {
            return;
        }
        
        _status = BAPromiseStatusResolved;
        _resolvedValue = value;
        
        void (^thenBlock)(NSObject*);
        while ([_thenQueue count] > 0) {
            thenBlock = [_thenQueue objectAtIndex:0];
            [_thenQueue removeObjectAtIndex:0];
            if (thenBlock) {
                thenBlock(value);
            }
        }
    }
}

- (void)reject:(nullable NSError*)error
{
    if (_status != BAPromiseStatusPending) {
        return;
    }
    
    _status = BAPromiseStatusRejected;
    _resolvedValue = error;
    
    if (_catchBlock) {
        _catchBlock(error);
    }
}

- (void)then:(void (^_Nonnull)(NSObject* _Nullable ))thenBlock
{
    @synchronized(_thenQueue) {
        if (_status == BAPromiseStatusResolved) {
            thenBlock(_resolvedValue);
        } else if (_status == BAPromiseStatusPending) {
            [_thenQueue addObject:thenBlock];
        }
    }
}

- (void)catch:(void (^_Nonnull)(NSError* _Nullable ))catchBlock
{
    if (_status == BAPromiseStatusRejected) {
        if ([_resolvedValue isKindOfClass:[NSError class]]) {
            catchBlock((NSError*)_resolvedValue);
        } else {
            catchBlock(nil);
        }
    } else if (_status == BAPromiseStatusPending) {
        _catchBlock = catchBlock;
    }
}

@end
