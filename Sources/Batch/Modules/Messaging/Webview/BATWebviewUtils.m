//
//  BATWebviewUtils.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BATWebviewUtils.h"

@implementation BATWebviewUtils

+ (nullable NSString*)analyticsIdForURL:(nonnull NSString*)url
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:url];
    if (urlComponents == nil) {
        return nil;
    }
    
    for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
        if ([@"batchAnalyticsID" isEqualToString:queryItem.name]) {
            return queryItem.value;
        }
    }
    
    return nil;
}

@end
