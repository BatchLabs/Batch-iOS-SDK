//
//  BAWebserviceResponsePush.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSResponsePushToken.h>

@implementation BAWSResponsePushToken

// Default constructor.
- (instancetype)initWithResponse:(NSDictionary *)response
{
    self = [super initWithResponse:response];
    
    if ([BANullHelper isNull:self] == YES)
    {
        return nil;
    }
    
    return self;
}

@end
