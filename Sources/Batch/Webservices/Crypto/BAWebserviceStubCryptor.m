//
//  BAWebserviceDummyCryptor.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWebserviceStubCryptor.h>

@implementation BAWebserviceStubCryptor

- (instancetype)initWithKey:(NSString*)key version:(NSString*)version
{
    self = [super init];
    if (self) {
    }
    return self;
}

// On error, the result will be null. No error message is supported for now
- (nullable NSData*)encrypt:(NSData*)data {
    return data;
}

- (nullable NSData*)decrypt:(NSData*)data {
    return data;
}

@end
