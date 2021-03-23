//
//  BASHA.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BASHA.h>
#import <CommonCrypto/CommonCrypto.h>

@implementation BASHA

+ (nullable NSData*)sha256HashOf:(nullable NSData*)data
{
    if (data == nil || data.length == 0) {
        return nil;
    }
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (int)data.length, digest);
    
    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

+ (nullable NSData*)sha1HashOf:(nullable NSData*)data
{
    if (data == nil || data.length == 0) {
        return nil;
    }
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (int)data.length, digest);
    
    return [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
}

@end
