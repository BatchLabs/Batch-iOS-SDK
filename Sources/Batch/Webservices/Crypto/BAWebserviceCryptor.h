//
//  BAWebserviceCipher.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol BAWebserviceCryptor <NSObject>

- (nullable instancetype)initWithKey:(NSString*)key version:(NSString*)version;

// On error, the result will be null. No error message is supported for now
- (nullable NSData*)encrypt:(NSData*)data;

- (nullable NSData*)decrypt:(NSData*)data;

@end

NS_ASSUME_NONNULL_END
