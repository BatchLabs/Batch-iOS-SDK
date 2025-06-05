//
//  BAConnection.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAConnection.h>

#import <Batch/BAInjection.h>
#import <Batch/BALogger.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAParameter.h>
#import <Batch/BARandom.h>
#import <Batch/BAThreading.h>
#import <Batch/BAWebserviceCryptor.h>
#import <Batch/Batch-Swift.h>

#define DEFAULT_RETRY_AFTER @60 // seconds

// Internal methods and parameters.
@interface BAConnection ()

@property BAConnectionMethod method;

// Link to the NSURLSession currently used.
@property NSURLSession *session;

// Link to the NSURLSessionDataTask currently used.
@property NSURLSessionDataTask *dataTask;

@end

@implementation BAConnection

#pragma mark -
#pragma mark Public methods

+ (BAConnectionErrorCause)errorCauseForError:(NSError *)error {
    if ([error.domain isEqualToString:ERROR_DOMAIN]) {
        return error.code;
    }

    if ((error.code >= 100 && error.code < 200) || error.code >= 400) {
        // HTTP Error
        return BAConnectionErrorCauseServerError;
    } else {
        switch (error.code) {
            case -1200: // kCFURLErrorSecureConnectionFailed
            case -1201: // kCFURLErrorServerCertificateHasBadDate
            case -1202: // kCFURLErrorServerCertificateUntrusted
            case -1203: // kCFURLErrorServerCertificateHasUnknownRoot
            case -1204: // kCFURLErrorServerCertificateNotYetValid
            case -1205: // kCFURLErrorClientCertificateRejected
            case -1206: // kCFURLErrorClientCertificateRequired
                return BAConnectionErrorCauseSSLHandshakeFailure;
            case -1001: // kCFURLErrorTimedOut
            case -1004: // kCFURLErrorCannotConnectToHost
            case -1005: // kCFURLErrorNetworkConnectionLost
            case -1009: // kCFURLErrorNotConnectedToInternet
                return BAConnectionErrorCauseNetworkTimeout;
            case -1000: // KCFErrorDomainCFNetwork
            case -1003: // kCFURLErrorCannotFindHost
                [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] updateDomainIfNeeded];
                return BAConnectionErrorCauseNetworkTimeout;
            default:
                return BAConnectionErrorCauseOther;
        }
    }
    return BAConnectionErrorCauseOther;
}

- (nonnull instancetype)initWithSession:(nonnull id<BAURLSessionProtocol>)session
                            contentType:(BAConnectionContentType)contentType
                               delegate:(nullable id<BAConnectionDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _session = session;
        _headers = [[NSMutableDictionary alloc] init];
        _timeout = 60;
        _canBypassOptOut = false;
        _contentType = contentType;
        _isDowngradedCipher = [BAParameter objectForKey:kParametersCipherV2LastFailure fallback:nil] != nil;
    }

    return self;
}

- (void)configureWithMethod:(BAConnectionMethod)method
                        url:(nonnull NSURL *)url
                       body:(nullable NSData *)body
             cryptorFactory:(nullable Class<BAWebserviceCryptorFactoryProtocol>)cryptorFactory {
    _url = url;
    _method = method;
    _body = body;
    _cryptorFactory = cryptorFactory;

    [_headers setValue:@"gzip" forKey:@"Accept-Encoding"];
    [_headers setValue:[BARandom generateUUID] forKey:@"X-Batch-Nonce"];

    NSString *cipherVersion = @"2";
    if (_isDowngradedCipher) {
        [_headers setValue:@"1" forKey:@"X-Batch-Cipher-Downgraded"];
        cipherVersion = @"1";
    }

    // Add response body cipher version
    [_headers setValue:cipherVersion forKey:@"X-Batch-Accept-Cipher"];
    if (method == BAConnectionMethodPost) {
        // Add request body cipher version
        [_headers setValue:cipherVersion forKey:@"X-Batch-Content-Cipher"];
    }
}

// Start the query asynchronously.
- (void)start {
    if ([[BAOptOut instance] isOptedOut] && !self.canBypassOptOut) {
        [BALogger debugForDomain:@"BAConnection"
                         message:@"Refusing to execute webservice client, as Batch is opted-out from, and webservice "
                                 @"isn't whitelisted"];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [self.delegate connectionDidFinishSuccessfully:NO];
        });

        NSError *err = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN
                                           code:BAConnectionErrorCauseOptedOut
                                       userInfo:nil];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [self.delegate connectionFailedWithError:err];
        });

        return;
    }

    // Clear current connection if any.
    if (self.dataTask != nil) {
        [self.dataTask cancel];
        self.dataTask = nil;
        self.session = nil;
    }

    NSError *err = nil;
    NSURLRequest *request = [self buildRequestWithError:&err];

    if (request == nil) {
        [self.delegate connectionFailedWithError:err];
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self.delegate connectionWillStart];
    });

    self.dataTask = [self.session
        dataTaskWithRequest:request
          completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
            [self handleDataTaskResponse:response data:data error:error];
          }];

    [self.dataTask resume];
}

#pragma mark -
#pragma mark Private methods

- (nullable NSString *)contentTypeString {
    switch (_contentType) {
        case BAConnectionContentTypeJSON:
            return @"application/json";
        case BAConnectionContentTypeMessagePack:
            return @"application/msgpack";
    }
    return nil;
}

- (NSMutableURLRequest *)buildRequestWithError:(NSError **)error {
    // Replace error with a dummy variable if it's null, so we don't have to check each time
    if (error == NULL) {
        __autoreleasing NSError *fakeOutErr;
        error = &fakeOutErr;
    }
    *error = nil;

    // Setup request.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                            timeoutInterval:self.timeout];

    for (NSString *key in self.headers) {
        NSString *value = [self.headers objectForKey:key];

        if ([BANullHelper isStringEmpty:value] == NO) {
            [request setValue:value forHTTPHeaderField:key];
        }
    }

    if (self.method == BAConnectionMethodGet) {
        [request setHTTPMethod:@"GET"];

        NSString *contentTypeHeaderValue = [self contentTypeString];

        if ([contentTypeHeaderValue length] > 0) {
            [request setValue:contentTypeHeaderValue forHTTPHeaderField:@"Accept"];
        }
    } else if (self.method == BAConnectionMethodPost) {
        if (self.body == nil) {
            *error = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN
                                         code:BAConnectionErrorCauseRequestCreation
                                     userInfo:@{NSLocalizedDescriptionKey : @"No POST body set. Aborting connection."}];
            return nil;
        }

        NSData *data = self.body;
        if (_cryptorFactory != nil) {
            id<BAWebserviceCryptor> cryptor = [_cryptorFactory outboundCryptorForConnection:self];
            data = [cryptor encrypt:data];

            if (data == nil) {
                *error = [NSError
                    errorWithDomain:NETWORKING_ERROR_DOMAIN
                               code:BAConnectionErrorCauseRequestCreation
                           userInfo:@{NSLocalizedDescriptionKey : @"Could not encrypt data. Aborting connection."}];
                return nil;
            }
        }

        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:data];

        NSString *contentTypeHeaderValue = [self contentTypeString];

        if ([contentTypeHeaderValue length] > 0) {
            [request setValue:contentTypeHeaderValue forHTTPHeaderField:@"Accept"];
            [request setValue:contentTypeHeaderValue forHTTPHeaderField:@"Content-Type"];
        }
    }

    id<BATWebserviceHMACProtocol> hmac = [_cryptorFactory hmacForContentType:_contentType];
    [hmac appendToMutableRequest:request];

    return request;
}

- (void)handleDataTaskResponse:(nullable NSURLResponse *)response
                          data:(nullable NSData *)data
                         error:(nullable NSError *)error {
    if (response == nil && error == nil) {
        error = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN
                                    code:BAConnectionErrorCauseOther
                                userInfo:@{@"subcode" : @1}];
        goto bail_on_err;
    }

    if (error == nil) {
        // There may still be an error, so we will handle them again later
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            error = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN
                                        code:BAConnectionErrorCauseOther
                                    userInfo:@{@"subcode" : @2}];
            goto bail_on_err;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode < 200 || statusCode >= 400) {
            NSString *serverError = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!serverError) {
                serverError = @"<undecodable>";
            }
            if (statusCode == 429) {
                NSDictionary *headers = [httpResponse allHeaderFields];
                NSString *retryAfterHeader = [headers objectForKey:@"Retry-After"];
                NSNumber *retryAfter = DEFAULT_RETRY_AFTER;
                if ([BANullHelper isStringEmpty:retryAfterHeader] == NO) {
                    retryAfter = [NSNumber numberWithInteger:[retryAfterHeader integerValue]];
                }
                error = [NSError
                    errorWithDomain:NETWORKING_ERROR_DOMAIN
                               code:BAConnectionErrorCauseServerTooManyRequest
                           userInfo:@{@"serverErrorBody" : serverError, @"subcode" : @3, @"retryAfter" : retryAfter}];
            } else {
                error = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN
                                            code:BAConnectionErrorCauseOther
                                        userInfo:@{@"serverErrorBody" : serverError, @"subcode" : @3}];
            }

            if (statusCode == kCipherFallbackHTTPErrorCode) {
                NSNumber *now = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
                [BAParameter setValue:now forKey:kParametersCipherV2LastFailure saved:true];
            }
            goto bail_on_err;
        }

        if (data == nil) {
            // We should NOT have a nil data at this point
            error = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN
                                        code:BAConnectionErrorCauseOther
                                    userInfo:@{@"subcode" : @4}];
            goto bail_on_err;
        }

        if (_cryptorFactory != nil) {
            id<BAWebserviceCryptor> cryptor = [_cryptorFactory inboundCryptorForData:data
                                                                          connection:self
                                                                            response:httpResponse];
            data = [cryptor decrypt:data];

            if (data == nil) {
                // We should NOT have a nil data at this point
                error = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN
                                            code:BAConnectionErrorCauseOther
                                        userInfo:@{@"subcode" : @5}];
                goto bail_on_err;
            }
        }
    }

bail_on_err:
    self.dataTask = nil;

    id<BAConnectionDelegate> strongDelegate = self.delegate;

    // Store the delegate before calling this, as it might disappear afterwards
    // The wrapping NSOperations should finish before handling the response somewhere else
    [strongDelegate connectionDidFinishSuccessfully:(error == nil)];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      if (error == nil) {
          [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] resetErrorCountIfNeeded];
          [strongDelegate connectionDidFinishLoadingWithData:data];
      } else {
          [strongDelegate connectionFailedWithError:error];
      }
    });

    return;
}
@end
