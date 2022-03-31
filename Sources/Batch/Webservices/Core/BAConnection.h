//
//  BAConnection.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAConnectionContentType.h>
#import <Batch/BAConnectionDelegate.h>
#import <Batch/BAURLSessionProtocol.h>
#import <Batch/BAWebserviceCryptorFactory.h>

@class BAConnection;

typedef NS_ENUM(NSUInteger, BAConnectionMethod) {
    BAConnectionMethodGet,
    BAConnectionMethodPost,
};

#pragma mark -
#pragma mark BAConnectionErrorCause

/*!
 @enum BAConnectionErrorCause
 @abstract Possible causes of webservice failure.
 */
enum
{
    /*!
     Value in BAConnectionErrorCauseNone when there is no error.
     */
    BAConnectionErrorCauseNone                = 0,
    
    
    /*!
     Value in BAConnectionErrorCauseParsingError when there was a parsing error.
     */
    BAConnectionErrorCauseParsingError        = 100,
    
    /*!
     Value in BAConnectionErrorCauseNetworkUnavailable when the response is in [100;200[ or >= 400 .
     */
    BAConnectionErrorCauseServerError         = 200,
    
    /*!
     Value in BAConnectionErrorCauseNetworkTimeout when the network timed out.
     */
    BAConnectionErrorCauseNetworkTimeout      = 300,
    
    /*!
     Value in BAConnectionErrorCauseSslHandshakeFailure when the SSL Handshake failed.
     */
    BAConnectionErrorCauseSSLHandshakeFailure = 400,
    
    /*!
     Value in BAConnectionErrorCauseOther when the error is of another type than the specified ones.
     */
    BAConnectionErrorCauseOther               = 500,
    
    /*!
     Batch has been opted-out from: Webservice calls are not allowed
     */
    BAConnectionErrorCauseOptedOut            = 600,
    
    /*!
     Could not serialize the request body
     */
    BAConnectionErrorCauseSerialization       = 700,
    
    /*!
     Could not create the URL Request
     */
    BAConnectionErrorCauseRequestCreation     = 800,
    
    /*!
     Server respond with http code 429 (overloaded)
     */
    BAConnectionErrorCauseServerTooManyRequest     = 900,
};
/*!
 @typedef BAConnectionErrorCause
 */
typedef NSInteger BAConnectionErrorCause;

#pragma mark -
#pragma mark BAConnection interface

/*!
 @class BAConnection
 @abstract This class provide implementation of NSURLSession and handle auto retring. NSURLConnection variant is available in BAConnectionCompat.
 @discussion This object use default value that you can override:
 timeout = 60
 numberOfRetry = 0
 cachePolicy = NSURLRequestReloadIgnoringLocalCacheData
 */
@interface BAConnection : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, nonnull) NSURL *url;

@property (readonly, nonnull) NSMutableDictionary *headers;

@property (nullable) NSData *body;

@property BAConnectionContentType contentType;

@property (nullable) Class<BAWebserviceCryptorFactoryProtocol> cryptorFactory;

/*!
 @property timeout
 @abstract The number of second before the query is considerated as failed without response from the server. Default = 60.
 */
@property (nonatomic) NSTimeInterval timeout;

/*!
 @property _delegate
 @abstract The delegate implementing the BAConnectionDelegate protocol.
 */
@property (weak, nonatomic, nullable) id<BAConnectionDelegate> delegate;

/**
 Is the webservice using a cipher v1 fallback
 */
@property (readonly, nonatomic) BOOL isDowngradedCipher;

/*!
 Controls whether this connection can bypass the global Opt-Out
 */
@property (nonatomic) BOOL canBypassOptOut;


/*!
 @method errorCauseForError:
 @abstract Get the BAConnectionErrorCause associated to a NSError emitted from the connection
 @return The error cause as a value of the BAConnectionErrorCause enum
 */
+ (BAConnectionErrorCause)errorCauseForError:(nonnull NSError *)error;

- (nonnull instancetype)initWithSession:(nonnull id<BAURLSessionProtocol>)session
                            contentType:(BAConnectionContentType)contentType
                               delegate:(nullable id<BAConnectionDelegate>)delegate;

- (void)configureWithMethod:(BAConnectionMethod)method
                        url:(nonnull NSURL*)url
                       body:(nullable NSData*)body
             cryptorFactory:(nullable id<BAWebserviceCryptorFactoryProtocol>)cryptorFactory;

- (void)start;

@end
