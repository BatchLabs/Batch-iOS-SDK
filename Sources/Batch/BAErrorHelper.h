//
//  BAErrorHelper.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BAInternalFailReason) {
    /*!
     A network problem occurred.
     */
    BAInternalFailReasonNetworkError = -10,

    /*!
     Invalid API key.
     */
    BAInternalFailReasonInvalidAPIKey = -20,

    /*!
     Deactivated API Key.
     */
    BAInternalFailReasonDeactivatedAPIKey = -30,

    /*!
     Another problem occurred. A retry can succeed
     */
    BAInternalFailReasonUnexpectedError = -50,

    /*!
     Batch has been globally opted out from
     */
    BAInternalFailReasonOptedOut = -60
};

/*!
 @class BAErrorHelper
 @abstract Used to generate all the public errors and exceptions.
 @discussion Place a simple NSException and a NSError are generated here.
 */
@interface BAErrorHelper : NSObject

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method errorMissingDevKey
 @abstract Error when the API key is missing.
 @return The corresponding NSError.
 */
+ (NSError *)errorMissingAPIKey __attribute__((warn_unused_result));

/*!
 @method errorAlreadyStarted
 @abstract Error when the library is already started.
 @return The corresponding NSError.
 */
+ (NSError *)errorAlreadyStarted __attribute__((warn_unused_result));

/*!
 @method errorInvalidAPIKey
 @abstract Error when the API key is invalid.
 @return The corresponding NSError.
 */
+ (NSError *)errorInvalidAPIKey __attribute__((warn_unused_result));

/*!
 @method serverError
 @abstract Error when the server return a malformed response.
 @return The corresponding NSError.
 */
+ (NSError *)serverError __attribute__((warn_unused_result));

/*!
 @method internalError
 @abstract Error when something goes wrong inside Batch code.
 @return The corresponding NSError.
 */
+ (NSError *)internalError __attribute__((warn_unused_result));

/*!
 @method webserviceError
 @abstract A webservice has generated an error.
 @return The corresponding NSError.
 */
+ (NSError *)webserviceError __attribute__((warn_unused_result));

/*!
 @method optedOutError
 @abstract The operation could not succeed as Batch has been Opted Out from
 @return The corresponding NSError.
 */
+ (NSError *)optedOutError;

/*!
 @method errorInvalidMessagingDelegate
 @abstract Error when a given messaging delegate is invalid.
 @return The corresponding NSError.
 */

+ (NSError *)errorInvalidMessagingDelegate __attribute__((warn_unused_result));

@end
