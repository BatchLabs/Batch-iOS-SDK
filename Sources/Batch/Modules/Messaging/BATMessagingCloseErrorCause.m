//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BATMessagingCloseErrorCause.h"

NSString * const kBATMessagingCloseErrorCauseKey = @"batch.messaging.close_error_cause";

@implementation BATMessagingCloseErrorHelper

+ (BATMessagingCloseErrorCause)guessErrorCauseForError:(nullable NSError*)error
{
    if (error == nil) {
        return BATMessagingCloseErrorCauseUnknown;
    }
    
    // If the error comes with an attached cause, use it.
    NSNumber *attachedCause = [self sanitizedUserInfoErrorCause:error.userInfo[kBATMessagingCloseErrorCauseKey]];
    if (attachedCause != nil) {
        return [attachedCause integerValue];
    }
    
    BATMessagingCloseErrorCause errorCause = BATMessagingCloseErrorCauseUnknown;
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        switch (error.code) {
            case NSURLErrorCancelled:
            case NSURLErrorUnknown:
            case NSURLErrorTimedOut:
            case NSURLErrorCannotFindHost:
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorDNSLookupFailed:
            case NSURLErrorDownloadDecodingFailedMidStream:
            case NSURLErrorDownloadDecodingFailedToComplete:
            case NSURLErrorInternationalRoamingOff:
            case NSURLErrorCallIsActive:
            case NSURLErrorDataNotAllowed:
            case NSURLErrorRequestBodyStreamExhausted:
                errorCause = BATMessagingCloseErrorCauseClientNetwork;
                break;
            default:
                errorCause = BATMessagingCloseErrorCauseServerFailure;
                break;
        }
    }
    
    return errorCause;
}

+ (NSNumber*)sanitizedUserInfoErrorCause:(nullable id)rawErrorCause
{
    if (![rawErrorCause isKindOfClass:NSNumber.class]) {
        return nil;
    }
    
    switch ([(NSNumber*)rawErrorCause integerValue]) {
        case BATMessagingCloseErrorCauseUnknown:
        case BATMessagingCloseErrorCauseServerFailure:
        case BATMessagingCloseErrorCauseClientNetwork:
        case BATMessagingCloseErrorCauseInvalidResponse:
            return rawErrorCause;
            
        default:
            return nil;
    }
}

@end
