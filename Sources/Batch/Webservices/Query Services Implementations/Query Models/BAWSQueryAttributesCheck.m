//
//  BAWSQueryAttributesCheck.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSQueryAttributesCheck.h>

@interface BAWSQueryAttributesCheck () {
    NSString *_transactionID;
    long long _version;
}
@end

@implementation BAWSQueryAttributesCheck

// Standard constructor.
- (id<BAWSQuery>)initWithTransactionID:(nonnull NSString *)transaction andVersion:(long long)version {
    self = [super initWithType:kQueryWebserviceTypeAttributesCheck];
    if (self) {
        _transactionID = transaction;
        _version = version;
    }

    return self;
}

// Build the basic object to send to the server as a query.
- (NSMutableDictionary *)objectToSend;
{
    NSMutableDictionary *dictionary = [super objectToSend];

    [dictionary setObject:@(_version) forKey:@"ver"];
    [dictionary setObject:_transactionID forKey:@"trid"];

    return dictionary;
}

@end
