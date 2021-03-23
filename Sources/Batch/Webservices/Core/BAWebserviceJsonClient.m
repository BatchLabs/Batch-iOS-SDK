//
//  BAWebserviceJsonClient.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceJsonClient.h>

@implementation BAWebserviceJsonClient

- (nullable instancetype)initWithMethod:(BAWebserviceClientRequestMethod)method
                                    URL:(nullable NSURL*)url
                               delegate:(nullable id<BAConnectionDelegate>)delegate
{
    return [super initWithMethod:method URL:url contentType:BAConnectionContentTypeJSON delegate:delegate];
}

#pragma mark -
#pragma mark Overridable request building methods

- (nonnull NSMutableDictionary *)requestBodyDictionary
{
    // Children should implement this method to provide body data
    // This will not be used for GET requests
    return [NSMutableDictionary new];
}

#pragma mark -
#pragma mark Private methods

- (nullable NSData *)requestBody:(NSError **)error
{
    return [self generateBodyWithError:error];
}

// Generate the data body, which is the requestBodyDictionary encoded as json
- (NSData*)generateBodyWithError:(NSError**)error
{
    // Replace error with a dummy variable if it's null, so we don't have to check each time
    if (error == NULL) {
        __autoreleasing NSError *fakeOutErr;
        error = &fakeOutErr;
    }
    *error = nil;
    
    NSDictionary *bodyDictionary = [self requestBodyDictionary];
    if (bodyDictionary == nil) {
        bodyDictionary = [NSMutableDictionary new];
    }
    
    if (![NSJSONSerialization isValidJSONObject:bodyDictionary]) {
        *error = [NSError errorWithDomain:NETWORKING_ERROR_DOMAIN code:BAConnectionErrorCauseSerialization userInfo:@{NSLocalizedDescriptionKey: @"Body is not a valid JSON object"}];
        return nil;
    }
    
    NSError *jsonErr = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDictionary options:0 error:&jsonErr];
    if (jsonErr != nil) {
        *error = jsonErr;
        return nil;
    }
    
    return jsonData;
}

@end
