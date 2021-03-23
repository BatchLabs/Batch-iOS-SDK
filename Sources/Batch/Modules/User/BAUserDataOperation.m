//
//  BAUserDataOperation.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BAUserDataOperation.h>

@implementation BAUserDataOperation

- (instancetype)initWithBlock:(BOOL (^)(void))block
{
    self = [super init];
    if (self)
    {
        _operationBlock = block;
    }
    return self;
}

- (BOOL)run
{
    if (!_operationBlock)
        return YES;
    
    return _operationBlock();
}

@end
