//
//  BAAES.m
//  Core
//
//  https://batch.com
//  Copyright (c) 2012 Batch SDK. All rights reserved.
//

#import <Batch/BAAESB64Cryptor.h>

#import <CommonCrypto/CommonCryptor.h>

#import <Batch/BANullHelper.h>

@interface BAAESB64Cryptor ()
{
    // Cryptor key.
    NSString *_key;
    
    // Combined key.
    NSString *_combine;
}

// Return the current key to use.
- (NSString *)currentKey;

// AES encryption.
- (NSData *)encryptAES:(NSData *)data usingKey:(NSString *)key;

// AES uncryption.
- (NSData *)decryptAES:(NSData *)data usingKey:(NSString *)key;

@end

@implementation BAAESB64Cryptor


#pragma mark -
#pragma mark Public methods

// Instanciate the AES cryption with the cryption key.
- (instancetype)initWithKey:(NSString *)key
{
    if ([BANullHelper isStringEmpty:key] == YES)
    {
        return nil;
    }
    
    if (key.length > kCCKeySizeAES128)
    {
        return nil;
    }
    
    self = [super init];
    if ([BANullHelper isNull:self] == NO)
    {
        _key = key;
    }
    
    _combine = nil;
    
    return self;
}

- (void)setCombinedKey:(NSString *)key
{
    if ([BANullHelper isStringEmpty:key] == YES)
    {
        return;
    }
    
    _combine = [NSString stringWithFormat:key, _key];
}


// Encode a string data.
- (NSString *)encrypt:(NSString *)tocrypt
{
    if ([BANullHelper isStringEmpty:tocrypt] == YES)
    {
        return nil;
    }

    NSData *dataToEncrypt = [tocrypt dataUsingEncoding:NSUTF8StringEncoding];

    NSData *encryptedData = [self encryptData:dataToEncrypt];
 
    return [[NSString alloc] initWithData:encryptedData encoding:NSUTF8StringEncoding];
}

// Decode a string data.
- (NSString *)decrypt:(NSString *)crypted
{
    if ([BANullHelper isStringEmpty:crypted] == YES)
    {
        return nil;
    }

    NSData *cryptedData = [crypted dataUsingEncoding:NSUTF8StringEncoding];

    NSData *decryptedData = [self decryptData:cryptedData];
    
    if ([decryptedData length] == 0)
    {
        return nil;
    }
    
    NSString *value = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    
    if (value == nil)
    {
        return nil;
    }

    return value;
}

// Encrypt and b64 data
- (NSData *)encryptData:(NSData *)tocrypt
{
    if ([BANullHelper isDataEmpty:tocrypt] == YES)
    {
        return nil;
    }

    NSData *encryptedData = [self encryptAES:tocrypt usingKey:[self currentKey]];

    return [encryptedData base64EncodedDataWithOptions:0];
}

// Decode a data.
- (NSData *)decryptData:(NSData *)data
{
    if ([BANullHelper isDataEmpty:data] == YES)
    {
        return nil;
    }
    
    // Un-base64 data
    NSData *rawData = [[NSData alloc] initWithBase64EncodedData:data options:0];
    
    return [self decryptAES:rawData usingKey:[self currentKey]];
}


#pragma mark -
#pragma mark Private methods

- (NSString *)currentKey
{
    if ([BANullHelper isStringEmpty:_combine] == YES)
    {
        return _key;
    }
    
    return _combine;
}

// AES encryption.
- (NSData *)encryptAES:(NSData *)data usingKey:(NSString *)key
{
    char keyPtr[kCCKeySizeAES128+1];
    bzero( keyPtr, sizeof(keyPtr) );
    
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]; // Change from NSUTF16StringEncoding to NSUTF8StringEncoding
    size_t numBytesEncrypted = 0;
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCKeySizeAES128;
	void *buffer = malloc(bufferSize);
    
    CCCryptorStatus result = CCCrypt( kCCEncrypt, kCCAlgorithmAES128,kCCOptionPKCS7Padding | kCCOptionECBMode,
                                     keyPtr, kCCKeySizeAES128,  // Changed from 256 to 128
                                     NULL,
                                     [data bytes], [data length],
                                     buffer, bufferSize,
                                     &numBytesEncrypted );
    
    NSData *output = [[NSData alloc] initWithBytesNoCopy:buffer length:numBytesEncrypted];
    if( result == kCCSuccess )
    {
        return output;
    }
    
    return NULL;
}

// AES uncryption.
- (NSData *)decryptAES:(NSData *)data usingKey:(NSString *)key
{
    char  keyPtr[kCCKeySizeAES128+1];
    bzero( keyPtr, sizeof(keyPtr) );
    
    [key getCString: keyPtr maxLength: sizeof(keyPtr) encoding: NSUTF8StringEncoding]; // Change from NSUTF16StringEncoding to NSUTF8StringEncoding
    
    size_t numBytesEncrypted = 0;
    
    NSUInteger dataLength = [data length];
    
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer_decrypt = malloc(bufferSize);
    
    CCCryptorStatus result = CCCrypt( kCCDecrypt , kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,
                                     keyPtr, kCCBlockSizeAES128,  // Changed from 256 to 128
                                     NULL,
                                     [data bytes], [data length],
                                     buffer_decrypt, bufferSize,
                                     &numBytesEncrypted );
    
    NSData *output_decrypt = [[NSData alloc] initWithBytesNoCopy:buffer_decrypt length:numBytesEncrypted];
    if( result == kCCSuccess )
    {
        return output_decrypt;
    }
    return NULL;
}

@end
