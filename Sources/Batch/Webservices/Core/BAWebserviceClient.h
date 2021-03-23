//
//  BAWebserviceClient.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAConnection.h>

typedef NS_ENUM(NSUInteger, BAWebserviceClientRequestMethod) {
    BAWebserviceClientRequestMethodGet,
    BAWebserviceClientRequestMethodPost,
};

/*!
 @class BAWebserviceClient
 @abstract Abstract class that group common methods for all webservices.
 @warning This class is not mean to be instanciated, you should only instanciate childrens.
 */
@interface BAWebserviceClient : NSOperation <BAConnectionDelegate>


- (nullable instancetype)initWithMethod:(BAWebserviceClientRequestMethod)method
                                    URL:(nullable NSURL*)url
                            contentType:(BAConnectionContentType)contentType
                               delegate:(nullable id<BAConnectionDelegate>)delegate;

@property (readonly, nonnull) NSURL *url;

/**
 Query method (GET / POST)
 */
@property (readonly, nonatomic) BAWebserviceClientRequestMethod method;

/**
 Can the client bypass the global Opt-Out
 */
@property (readonly, nonatomic) BOOL canBypassOptOut;

/*!
 @method setTimeout:
 @abstract Change the request timeout. Default value is 60s
 @param seconds :   Number of seconds before the request timed out.
 */
- (void)setTimeout:(NSUInteger)seconds;

/*
 Query parameters to add
 */
- (nonnull NSMutableDictionary<NSString *, NSString *>*)queryParameters;

/*
 Body parameters to add
 Unused for GET requests
 */
- (nullable NSData *)requestBody:(NSError * _Nullable * _Nullable)error;

/*
 Additional HTTP headers
 */
- (nonnull NSMutableDictionary<NSString *, NSString *>*)requestHeaders;

/*
 Cryptor factory to use when sending/receiving data
 */
- (nullable Class<BAWebserviceCryptorFactoryProtocol>)cryptorFactory;

// NSOperation

/**
 Use BAWebserviceClientExecutor to run this
 */
- (void)start NS_UNAVAILABLE;

// BAConnectionProtocol
- (void)connectionWillStart NS_REQUIRES_SUPER;

- (void)connectionFailedWithError:(nonnull NSError *)error NS_REQUIRES_SUPER;

- (void)connectionDidFinishLoadingWithData:(nonnull NSData *)data NS_REQUIRES_SUPER;

- (void)connectionDidFinishSuccessfully:(BOOL)success NS_REQUIRES_SUPER;

@end
