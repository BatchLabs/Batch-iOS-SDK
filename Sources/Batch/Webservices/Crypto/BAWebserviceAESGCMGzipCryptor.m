//
//  BAWebserviceAESGCMGzipCryptor.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWebserviceAESGCMGzipCryptor.h>
#import <Batch/BATGZIP.h>

@implementation BAWebserviceAESGCMGzipCryptor

- (instancetype)initWithKey:(NSString*)key version:(NSString*)version
{
    self = [super initWithKey:key version:version];
    return self;
}

// On error, the result will be nil. No error message is supported for now
- (nullable NSData*)encrypt:(NSData*)data {
    
    NSData *compressedData = [BATGZIP dataByGzipping:data];
    if (compressedData == nil) {
        return nil;
    }
    
    return [super encrypt:compressedData];
}

- (nullable NSData*)decrypt:(NSData*)rawData {
    
    if (rawData == nil) {
        return nil;
    }
    
    NSData *decryptedData = [super decrypt:rawData];
    if (decryptedData == nil) {
        return nil;
    }
    
    return [BATGZIP dataByGunzipping:decryptedData];
}

@end

