//
//  BAGETWebserviceClient.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BAGETWebserviceClient.h>

#import <Batch/BAHTTPHeaders.h>
#import <Batch/BAParameter.h>
#import <Batch/BAStringUtils.h>

#define DEFAULT_GET_TIMEOUT 15 // Seconds

@interface BAGETWebserviceClient () {
    NSString *_identifier;
}

@end

@implementation BAGETWebserviceClient

- (instancetype)initWithURL:(nonnull NSURL *)url
                 identifier:(nonnull NSString *)identifier
                   delegate:(nullable id<BAConnectionDelegate>)delegate {
    self = [super initWithMethod:BAWebserviceClientRequestMethodGet URL:url delegate:delegate];
    if (self) {
        _identifier = [identifier copy];

        [BALogger debugForDomain:@"Webservice" message:@"GET URL: %@", url.absoluteString];

        [self setTimeout:DEFAULT_GET_TIMEOUT];
    }

    return self;
}

- (nonnull NSMutableDictionary<NSString *, NSString *> *)requestHeaders {
    NSMutableDictionary<NSString *, NSString *> *headers = [super requestHeaders];
    headers[@"User-Agent"] = [BAHTTPHeaders userAgent];
    return headers;
}

- (NSString *)webserviceIdentifier {
    return _identifier;
}

@end
