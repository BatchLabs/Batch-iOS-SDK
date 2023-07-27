//
//  BAWebserviceAESGCMGzipCryptor.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceAESGCMCryptor.h>
#import <Batch/BAWebserviceCryptor.h>

NS_ASSUME_NONNULL_BEGIN

/**
 AES-GCM GzipCryptor
 Also encodes its output as Base 64
 */
@interface BAWebserviceAESGCMGzipCryptor : BAWebserviceAESGCMCryptor <BAWebserviceCryptor>

- (nonnull instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithKey:(NSString *)key version:(NSString *)version NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
