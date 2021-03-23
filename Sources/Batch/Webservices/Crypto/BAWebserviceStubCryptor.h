//
//  BAWebserviceDummyCryptor.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceCryptor.h>

NS_ASSUME_NONNULL_BEGIN

// Stub cryptor that does absolutely nothing except returning the original data
@interface BAWebserviceStubCryptor : NSObject <BAWebserviceCryptor>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithKey:(NSString*)key version:(NSString*)version NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
