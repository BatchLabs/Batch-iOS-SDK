//
//  BAWSResponseAttributesCheck.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSResponse.h>

typedef NS_ENUM(NSUInteger, BAWSResponseAttrCheckAction) {
    BAWSResponseAttrCheckActionUnknown = 0,
    BAWSResponseAttrCheckActionOk = 1,
    BAWSResponseAttrCheckActionBump = 2,
    BAWSResponseAttrCheckActionResend = 3,
    BAWSResponseAttrCheckActionRecheck = 4
};

/*!
 @class BAWSResponseAttributesCheck
 @abstract Response of a BAWebserviceQueryAttributes.
 @discussion Build and serialize the response to the query.
 */
@interface BAWSResponseAttributesCheck : BAWSResponse <BAWSResponse>

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @property actionString
 @abstract Returned action. Supported actions: OK, BUMP, RESEND, RECHECK
 */
@property (readonly) NSString *actionString;

/*!
 @property action
 @abstract Action to perform. Parsed from actionString.
 */
@property (readonly) BAWSResponseAttrCheckAction action;

/*!
 @property version
 @abstract Returned data version. Only when action = BUMP
 */
@property (readonly) NSNumber *version;

/*!
 @property time
 @abstract Returned time to wait in ms. Only when action = RECHECK or RESEND. Default value is 15000 for RECHECK, 0 for
 RESEND
 */
@property (readonly) NSNumber *time;

/*!
 @property projectKey
 @abstract ProjectKey attached the application
 */
@property (readonly) NSString *projectKey;

@end
