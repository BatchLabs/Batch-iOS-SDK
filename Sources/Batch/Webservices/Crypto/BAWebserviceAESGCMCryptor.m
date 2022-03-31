//
//  BAWebserviceAESGCMCryptor.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWebserviceAESGCMCryptor.h>

#import <CommonCrypto/CommonCryptor.h>

#import <Batch/BARandom.h>

#define KEY_SIZE 8

@interface BAWebserviceAESGCMCryptor () {
    NSString *_key;
    NSString *_version;
}

@end

@implementation BAWebserviceAESGCMCryptor

- (instancetype)initWithKey:(NSString *)key version:(NSString *)version {
    self = [super init];
    if (self) {
        if ([BANullHelper isStringEmpty:key] || [BANullHelper isStringEmpty:version]) {
            return nil;
        }
        _key = key;
        _version = version;
    }
    return self;
}

// On error, the result will be nil. No error message is supported for now
- (nullable NSData *)encrypt:(NSData *)data {
    if (data == nil) {
        return nil;
    }

    // Encrypted data format is
    // Dynamic key ("1" + 7 random chars) + b64(aes encrypted data)

    NSString *randomPart = [self randomPart];

    NSData *cryptedData = [self performCryptoOperation:kCCEncrypt onData:data randomPart:randomPart];
    if (cryptedData == nil) {
        return nil;
    }

    cryptedData = [cryptedData base64EncodedDataWithOptions:0];

    NSMutableData *finalData = [[randomPart dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [finalData appendData:cryptedData];

    return finalData;
}

- (nullable NSData *)decrypt:(NSData *)rawData {
    if (rawData == nil) {
        return nil;
    }

    if (rawData.length <= KEY_SIZE) {
        // Data only contains the key, or even less. We expect at least one extra byte
        // to make the code simpler: the data would not make any sense without it anyway
        return nil;
    }

    NSData *dynamicKey = [rawData subdataWithRange:NSMakeRange(0, KEY_SIZE)];
    NSString *dynamicKeyString = [[NSString alloc] initWithData:dynamicKey encoding:NSUTF8StringEncoding];
    if (dynamicKeyString == nil) {
        return nil;
    }

    NSData *cryptedB64Data = [rawData subdataWithRange:NSMakeRange(KEY_SIZE, rawData.length - KEY_SIZE)];

    // We need to un-b64 the crypted data before decoding it
    NSData *cryptedData = [[NSData alloc] initWithBase64EncodedData:cryptedB64Data options:0];
    if (cryptedData == nil) {
        // Invalid b64 data
        return nil;
    }

    NSData *decryptedData = [self performCryptoOperation:kCCDecrypt onData:cryptedData randomPart:dynamicKeyString];

    return decryptedData;
}

- (NSString *)randomPart {
    // This cipher's dynamic key is version ("1" for v1, "2" for v2) + 7 random chars/numbers
    // -1ing the key size is important as "1" is part of it
    return [_version stringByAppendingString:[BARandom randomAlphanumericStringWithLength:KEY_SIZE - 1]];
}

- (nullable NSData *)performCryptoOperation:(CCOperation)operation
                                     onData:(NSData *)data
                                 randomPart:(NSString *)randomPart {
    if (data == nil || randomPart == nil) {
        return nil;
    }

    char cKeyPtr[kCCKeySizeAES128 + 1];
    bzero(cKeyPtr, sizeof(cKeyPtr));

    [[_key stringByAppendingString:randomPart] getCString:cKeyPtr
                                                maxLength:sizeof(cKeyPtr)
                                                 encoding:NSUTF8StringEncoding];

    size_t bufferSize = [data length] + kCCBlockSizeAES128;
    size_t outBytes = 0;
    void *outBuffer = malloc(bufferSize);

    CCCryptorStatus result =
        CCCrypt(operation, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode, cKeyPtr, kCCBlockSizeAES128,
                NULL, [data bytes], [data length], outBuffer, bufferSize, &outBytes);

    if (result == kCCSuccess) {
        return [[NSData alloc] initWithBytesNoCopy:outBuffer length:outBytes];
    }

    return nil;
}

@end
