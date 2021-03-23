//
//  BAWebserviceQuery.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSQuery.h>

#import <Batch/BARandom.h>

@implementation BAWSQuery

// Root initialization of all queries.
- (instancetype)initWithType:(NSString*)type
{
    self = [super init];
    
    if (self) {
        _identifier = [BARandom generateUUID];
        _type = type;
    }
    
    return self;
}

// Build the basic object to send to the server as a query.
- (NSMutableDictionary *)objectToSend
{
    NSMutableDictionary *outDict = [NSMutableDictionary new];
    outDict[kWebserviceKeyQueryIdentifier] = _identifier;
    outDict[kWebserviceKeyQueryType] = _type;
    return outDict;
}

@end
