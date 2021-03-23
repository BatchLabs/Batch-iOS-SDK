//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

// Defines the possible error clauses
// If you add a case here, don't forget to add it to "+sanitizedUserInfoErrorCause"
typedef NS_ENUM(NSUInteger, BATMessagingCloseErrorCause) {
    // Unknown error cause
    BATMessagingCloseErrorCauseUnknown = 0,
    
    // A server failure: bad SSL configuration, non 2xx HTTP status code
    BATMessagingCloseErrorCauseServerFailure = 1,
    
    // Unprocessable response (for example: a server served an image that could not be decoded)
    BATMessagingCloseErrorCauseInvalidResponse = 2,
    
    // Temporary network error, which may be the client's fault: DNS failure, Timeout, etc...
    BATMessagingCloseErrorCauseClientNetwork = 3
};

// Key for adding a messaging error cause in a NSError's userInfo dict
extern NSString * _Nonnull const kBATMessagingCloseErrorCauseKey;

@interface BATMessagingCloseErrorHelper : NSObject

+ (BATMessagingCloseErrorCause)guessErrorCauseForError:(nullable NSError*)error;

@end
