//
//  BAWebserviceCipherFactory.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAConnectionContentType.h>
#import <Batch/BATWebserviceHMAC.h>
#import <Batch/BAWebserviceCryptor.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BAConnection;

@protocol BAWebserviceCryptorFactoryProtocol <NSObject>

/**
 Cipher for outbound data
 (usually post data for webservices)
 */
//+ (nullable id<BAWebserviceCryptor>)outboundCryptorForContentType:(BAConnectionContentType)contentType;
+ (nullable id<BAWebserviceCryptor>)outboundCryptorForConnection:(BAConnection *)connection;

/**
 Cipher for inbound data
 (usually data from server replies)
 */
+ (nullable id<BAWebserviceCryptor>)inboundCryptorForData:(NSData *)data
                                               connection:(BAConnection *)connection
                                                 response:(NSHTTPURLResponse *)response;

/**
 HMAC Provider for specified content-type
 */
+ (nullable id<BATWebserviceHMACProtocol>)hmacForContentType:(BAConnectionContentType)contentType;

@end

@interface BAWebserviceCryptorFactory : NSObject <BAWebserviceCryptorFactoryProtocol>

@end

NS_ASSUME_NONNULL_END
