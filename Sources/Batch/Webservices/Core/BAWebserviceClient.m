//
//  BAWebserviceClient.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWebserviceClient.h>

#import <Batch/BAConnection.h>
#import <Batch/BAParameter.h>
#import <Batch/BAURLSession.h>

// Internal methods and parameters.
@interface BAWebserviceClient () {
   @private
    __weak id<BAConnectionDelegate> _delegate;

    // Link to the BAConnection currently used.
    BAConnection *_connection;
    BAWebserviceClientRequestMethod _method;

    BOOL _running;
}

/**
 Redeclaration of properties for NSOperation KVO
 */
@property (nonatomic, readwrite, getter=isExecuting) BOOL executing;
@property (nonatomic, readwrite, getter=isFinished) BOOL finished;

@end

@implementation BAWebserviceClient

/**
 Yes, even in 2019 we need to manually synthesize those properties
 This is because NSOperation expects weird KVO names that don't match property, so
 we have to rewrite them manually
 */
@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark -
#pragma mark Public methods

// Build a webservice with his url  and parameters types to add.
- (instancetype)initWithMethod:(BAWebserviceClientRequestMethod)method
                           URL:(NSURL *)url
                   contentType:(BAConnectionContentType)contentType
                      delegate:(id<BAConnectionDelegate>)delegate {
    self = [super init];
    if (self) {
        if (url == nil) {
            [BALogger debugForDomain:NETWORKING_ERROR_DOMAIN
                             message:@"Could not instanciate Webservice Client: URL is nil"];
            return nil;
        }

        _url = url;

        _method = method;

        if (delegate == self) {
            [BALogger
                debugForDomain:NETWORKING_ERROR_DOMAIN
                       message:
                           @"BAWebserviceClient has been instanciated with itself as a delegate. As it already acts as "
                           @"the BAConnection delegate, it has automatically been unset. Please fix your init call."];
            delegate = nil;
        }

        _delegate = delegate;

        // Build the connection.
        _connection = [[BAConnection alloc] initWithSession:[BAURLSession sharedSession]
                                                contentType:contentType
                                                   delegate:self];

        _connection.canBypassOptOut = [self canBypassOptOut];
    }

    return self;
}

// Change the request timeout. Default value is 60s
- (void)setTimeout:(NSTimeInterval)seconds {
    [_connection setTimeout:seconds];
}

- (BOOL)canBypassOptOut {
    return false;
}

#pragma mark -
#pragma mark Overridable request building methods

- (nonnull NSMutableDictionary<NSString *, NSString *> *)queryParameters {
    // Children should implement this method to provide URL Query items
    return [NSMutableDictionary new];
}

- (nullable NSData *)requestBody:(NSError **)error {
    // Children should implement this method to provide body data
    // This will not be used for GET requests
    return [NSData new];
}

- (nonnull NSMutableDictionary *)requestHeaders {
    return [NSMutableDictionary new];
}

- (nullable Class<BAWebserviceCryptorFactoryProtocol>)cryptorFactory {
    return [BAWebserviceCryptorFactory class];
}

#pragma mark -
#pragma mark NSOperation

- (void)start {
    [self executeNetworkRequest];
}

#pragma mark -
#pragma mark NSOperation KVO/Properties

- (BOOL)isAsynchronous {
    // We're an asynchronous task, as NSURLSession will make the request in another thread/process
    return true;
}

- (BOOL)isReady {
    return true;
}

- (void)setExecuting:(BOOL)executing {
    if (_executing != executing) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = executing;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    }
}

- (BOOL)isExecuting {
    return _executing;
}

- (void)setFinished:(BOOL)finished {
    if (_finished != finished) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = finished;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    }
}

- (BOOL)isFinished {
    return _finished;
}

#pragma mark -
#pragma mark BAConnectionDelegate
// All methods should be forwarded

- (void)connectionDidFinishLoadingWithData:(NSData *)data {
    [_delegate connectionDidFinishLoadingWithData:data];
}

- (void)connectionDidFinishSuccessfully:(BOOL)success {
    [self markAsFinished];
    [_delegate connectionDidFinishSuccessfully:success];
}

- (void)connectionFailedWithError:(NSError *)error {
    [_delegate connectionFailedWithError:error];
}

- (void)connectionWillStart {
    [_delegate connectionWillStart];
}

#pragma mark -
#pragma mark Private methods

// Configure the BAConnection
// This means building the final URL, and body if required
- (BOOL)configureConnection {
    BAConnectionMethod connectionMethod;
    switch (self.method) {
        case BAWebserviceClientRequestMethodGet:
        default:
            connectionMethod = BAConnectionMethodGet;
            break;
        case BAConnectionMethodPost:
            connectionMethod = BAConnectionMethodPost;
            break;
    }

    NSError *err = nil;
    NSData *body = [self requestBody:&err];

    if (err != nil) {
        NSError *publicErr = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN
                                                 code:BAConnectionErrorCauseSerialization
                                             userInfo:@{NSUnderlyingErrorKey : err}];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          [self->_delegate connectionFailedWithError:publicErr];
        });
        return false;
    }

    [_connection configureWithMethod:connectionMethod
                                 url:[self generateURL]
                                body:body
                      cryptorFactory:[self cryptorFactory]];

    [_connection.headers addEntriesFromDictionary:[self requestHeaders]];

    return true;
}

// Builds the URL using the base one, appending requested query parameters
- (NSURL *)generateURL {
    NSDictionary<NSString *, NSString *> *queryParameters = [self queryParameters];
    if ([queryParameters count] > 0) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:_url resolvingAgainstBaseURL:false];

        if (urlComponents != nil) {
            NSArray *originalQueryItems = urlComponents.queryItems;
            NSMutableArray *newQueryItems = originalQueryItems != nil
                                                ? [originalQueryItems mutableCopy]
                                                : [[NSMutableArray alloc] initWithCapacity:queryParameters.count];

            for (NSString *key in queryParameters.allKeys) {
                [newQueryItems addObject:[[NSURLQueryItem alloc] initWithName:key value:queryParameters[key]]];
            }

            urlComponents.queryItems = newQueryItems;
            NSURL *newURL = [urlComponents URL];
            if (newURL != nil) {
                return newURL;
            }
        }
    }

    return _url;
}

- (void)executeNetworkRequest {
    if (self.executing) {
        return;
    }

    self.executing = true;
    self.finished = false;

    if (![self configureConnection]) {
        [self markAsFinished];
        return;
    }

    [_connection start];
}

- (void)markAsFinished {
    if (self.executing) {
        self.executing = false;
        self.finished = true;
    }
}

@end
