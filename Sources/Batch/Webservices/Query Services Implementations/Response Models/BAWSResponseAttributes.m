//
//  BAWSResponseAttributes.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSResponseAttributes.h>

@implementation BAWSResponseAttributes

// Default constructor.
- (instancetype)initWithResponse:(NSDictionary *)response
{
    self = [super initWithResponse:response];
    
    if ([BANullHelper isNull:self] == YES)
    {
        return nil;
    }
    
    _transactionID = [response objectForKey:@"trid"];
    _version = [response objectForKey:@"ver"];
    
    // Sanity checks yay
    if (![_transactionID isKindOfClass:[NSString class]] || ![_version isKindOfClass:[NSNumber class]])
    {
        _transactionID = nil;
        _version = nil;
    }
    
    return self;
}

@end
