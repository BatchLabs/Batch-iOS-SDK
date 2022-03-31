//
//  BAErrorHelper.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAErrorHelper.h>

@implementation BAErrorHelper

// Error when the API key is missing.
+ (NSError *)errorMissingAPIKey {
    return [NSError errorWithDomain:ERROR_DOMAIN
                               code:BAInternalFailReasonInvalidAPIKey
                           userInfo:@{NSLocalizedDescriptionKey : @"Empty or void API key."}];
}

// Error when the library is already started.
+ (NSError *)errorAlreadyStarted {
    return [NSError errorWithDomain:ERROR_DOMAIN
                               code:BAInternalFailReasonUnexpectedError
                           userInfo:@{NSLocalizedDescriptionKey : @"Batch is already started, restarting again."}];
}

// Error when the library is stopped on an unclock code is required.
+ (NSError *)errorBatchStoppedOnRedeem {
    return [NSError
        errorWithDomain:ERROR_DOMAIN
                   code:BAInternalFailReasonUnexpectedError
               userInfo:@{
                   NSLocalizedDescriptionKey :
                       @"Cannot provide any item if Batch is not started, call startWithAPIKey:completion: before."
               }];
}

// Error when the input URL is missing.
+ (NSError *)errorURLNotFound {
    return [NSError errorWithDomain:ERROR_DOMAIN
                               code:BAInternalFailReasonUnexpectedError
                           userInfo:@{NSLocalizedDescriptionKey : @"No URL found."}];
}

// Error when no code is found.
+ (NSError *)errorCodeNotFound {
    return [NSError errorWithDomain:ERROR_DOMAIN
                               code:BAInternalFailReasonUnexpectedError
                           userInfo:@{NSLocalizedDescriptionKey : @"No code found."}];
}

// Error when the API key is invalid.
+ (NSError *)errorInvalidAPIKey {
    return [NSError errorWithDomain:ERROR_DOMAIN code:BAInternalFailReasonInvalidAPIKey userInfo:nil];
}

// Error when the server return a malformed response.
+ (NSError *)serverError {
    return [NSError errorWithDomain:ERROR_DOMAIN
                               code:BAInternalFailReasonUnexpectedError
                           userInfo:@{NSLocalizedDescriptionKey : @"Server error."}];
}

// Error when Batch has been Opted Out from
+ (NSError *)optedOutError {
    return [NSError
        errorWithDomain:ERROR_DOMAIN
                   code:BAInternalFailReasonOptedOut
               userInfo:@{
                   NSLocalizedDescriptionKey : @"Could not perform operation: Batch has been globally Opted Out from."
               }];
}

// Error when something goes wrong inside Batch code.
+ (NSError *)internalError {
    return [NSError errorWithDomain:ERROR_DOMAIN
                               code:BAInternalFailReasonUnexpectedError
                           userInfo:@{NSLocalizedDescriptionKey : @"Internal error."}];
}

// A webservice has generated an error.
+ (NSError *)webserviceError {
    return [NSError errorWithDomain:ERROR_DOMAIN
                               code:BAInternalFailReasonNetworkError
                           userInfo:@{NSLocalizedDescriptionKey : @"Network error."}];
}

// Error when a given delegate is invalid.
+ (NSError *)errorInvalidMessagingDelegate {
    return [NSError errorWithDomain:ERROR_DOMAIN
                               code:BAInternalFailReasonUnexpectedError
                           userInfo:@{NSLocalizedDescriptionKey : @"The provided messaging delegate is invalid."}];
}

@end
