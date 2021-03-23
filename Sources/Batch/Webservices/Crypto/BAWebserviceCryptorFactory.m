//
//  BAWebserviceCipherFactory.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWebserviceCryptorFactory.h>

#import <Batch/BAConnection.h>
#import <Batch/BAWebserviceStubCryptor.h>
#import <Batch/BAWebserviceAESGCMCryptor.h>
#import <Batch/BAWebserviceAESGCMGzipCryptor.h>

@implementation BAWebserviceCryptorFactory

+ (nullable id<BAWebserviceCryptor>)outboundCryptorForConnection:(BAConnection*)connection
{
    if (connection.contentType == BAConnectionContentTypeJSON) {
        // We only support one outbound cipher at the time for now
        if (connection.isDowngradedCipher) {
            return [[BAWebserviceAESGCMCryptor alloc] initWithKey:self._baDebugDescription version:@"1"];
        } else {
            return [[BAWebserviceAESGCMGzipCryptor alloc] initWithKey:self._baDebugDescriptionV2 version:@"2"];
        }
    }
    return [[BAWebserviceStubCryptor alloc] initWithKey:@"" version:@""];
    
}

+ (nullable id<BAWebserviceCryptor>)inboundCryptorForData:(NSData*)data connection:(BAConnection*)connection response:(NSHTTPURLResponse*)response
{
    if (connection.contentType == BAConnectionContentTypeJSON && data != nil && data.length > 0) {
        NSString *payloadVersion = [self valueForHTTPHeaderKey:@"X-Batch-Content-Cipher" response:response];
        if ([@"2" isEqualToString:payloadVersion]) {
            return [[BAWebserviceAESGCMGzipCryptor alloc] initWithKey:self._baDebugDescriptionV2 version:@"2"];
        } else {
            return [[BAWebserviceAESGCMCryptor alloc] initWithKey:self._baDebugDescription version:@"1"];
        }
    }
    return [[BAWebserviceStubCryptor alloc] initWithKey:@"" version:@""];
}

+ (nullable id<BATWebserviceHMACProtocol>)hmacForContentType:(BAConnectionContentType)contentType
{
    // We're enabling HMAC for everybody for testing purposes
    return [[BATWebserviceHMAC alloc] initWithKey:self._baLocalizedDebugDescription];
}

+ (NSString*)valueForHTTPHeaderKey:(nonnull NSString*)key response:(NSHTTPURLResponse*)response
{
    NSDictionary *headers = [response allHeaderFields];
    NSString *value = [headers valueForKey:key];
    if (![BANullHelper isStringEmpty:value]) {
        return value;
    }
    return nil;
}

// This name is volountarily bad ot
// Act like this is named "+(NSString*)key"
+ (NSString*)_baDebugDescription
{
    return [NSString stringWithFormat:@"%@%irM",BAPrivateKeyWebservice,33];
}

// Same
+ (NSString*)_baDebugDescriptionV2
{
    return [NSString stringWithFormat:@"%@%iHVJ",BAPrivateKeyWebserviceV2,4];
}

// Same
+ (NSString*)_baLocalizedDebugDescription
{
    return [NSString stringWithFormat:@"%@1%@3O%@2", @"B!", @"]oOt/@kE]ZQMtZv-", @"ikNIVZ&aOq"];
}

@end
