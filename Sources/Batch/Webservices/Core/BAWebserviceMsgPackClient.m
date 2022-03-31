//
//  BAWebserviceMsgPackClient.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAHTTPHeaders.h>
#import <Batch/BAWebserviceMsgPackClient.h>

#define BA_METRIC_HEADER_SDK_VERSION @"x-batch-sdk-version"
#define BA_METRIC_HEADER_SCHEMA_VERSION @"x-batch-protocol-version"
#define BA_METRIC_SCHEMA_VERSION @"1.0.0"

@implementation BAWebserviceMsgPackClient

- (nullable instancetype)initWithMethod:(BAWebserviceClientRequestMethod)method
                                    URL:(nullable NSURL *)url
                               delegate:(nullable id<BAConnectionDelegate>)delegate {
    return [super initWithMethod:method URL:url contentType:BAConnectionContentTypeMessagePack delegate:delegate];
}

- (nonnull NSMutableDictionary *)requestHeaders {
    NSMutableDictionary *headers = [super requestHeaders];
    headers[@"User-Agent"] = [BAHTTPHeaders userAgent];
    headers[BA_METRIC_HEADER_SCHEMA_VERSION] = [self schemaVersion];
    headers[BA_METRIC_HEADER_SDK_VERSION] = @(BAAPILevel);
    return headers;
}

- (NSString *)schemaVersion {
    return BA_METRIC_SCHEMA_VERSION;
}

@end
