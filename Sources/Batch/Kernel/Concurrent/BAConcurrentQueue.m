//
//  BAConcurrentQueue.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAConcurrentQueue.h>

@interface BAConcurrentQueue ()
{
    NSMutableArray *_backingArray;
    dispatch_queue_t _dispatchQueue;
}

@end

@implementation BAConcurrentQueue

#pragma mark Public methods

- (void)push:(NSObject *)object
{
    if( object )
    {
        dispatch_async(_dispatchQueue, ^{
            [self->_backingArray insertObject:object atIndex:0];
        });
    }
}

- (NSObject *)poll
{
    __block NSObject *result = nil;
    dispatch_sync(_dispatchQueue, ^{
        if( [self->_backingArray count] > 0 )
        {
            result = [self->_backingArray lastObject];
            [self->_backingArray removeLastObject];
        }
    });
    return result;
}

- (NSArray *)pollAll
{
    __block NSArray *result = [NSArray array];
    dispatch_sync(_dispatchQueue, ^{
        if( [self->_backingArray count] > 0 )
        {
            result = [NSArray arrayWithArray:self->_backingArray];
            [self->_backingArray removeAllObjects];
        }
    });
    return result;
}

- (BOOL)empty
{
    __block BOOL result;
    dispatch_sync(_dispatchQueue, ^{
        result = ([self->_backingArray count] == 0);
    });
    return result;
}

- (void)clear
{
    dispatch_sync(_dispatchQueue, ^{
        [self->_backingArray removeAllObjects];
    });
}

- (NSUInteger)count
{
    __block NSUInteger result;
    dispatch_sync(_dispatchQueue, ^{
        result = [self->_backingArray count];
    });
    return result;
}

#pragma mark Private methods

- (instancetype)init
{
    self = [super init];
    
    if( [BANullHelper isNull:self] )
    {
        return nil;
    }
    
    _dispatchQueue = dispatch_queue_create("com.batch.ios.concurrent.queue", NULL);
    _backingArray = [NSMutableArray new];
    
    return self;
}

- (void)dealloc
{
    // We need to dispatch_release for iOS 5 devices. If we don't set the variable to NULL we crash on iOS 6+ devices.
    if( _dispatchQueue )
    {
        _dispatchQueue = NULL;
    }
}

@end
