//
//  BAAESB64Cryptor.h
//  Core
//
//  https://batch.com
//  Copyright (c) 2012 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAEncryptionProtocol.h>

/*!
 @class BAAESB64Cryptor
 @abstract AES+B64 cryptor data.
 */
@interface BAAESB64Cryptor : NSObject <BAEncryptionProtocol>

- (instancetype)init NS_UNAVAILABLE;

@end
