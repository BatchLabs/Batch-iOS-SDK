//
//  BAWSResponseAttributes.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSResponse.h>

/*!
 @class BAWSResponseAttributes
 @abstract Response of a BAWebserviceQueryAttributes.
 @discussion Build and serialize the response to the query.
 */
@interface BAWSResponseAttributes : BAWSResponse <BAWSResponse>

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @property transactionID
 @abstract Returned transaction ID.
 */
@property (readonly) NSString *transactionID;

/*!
 @property version
 @abstract Returned data version.
 */
@property (readonly) NSNumber *version;

@end
