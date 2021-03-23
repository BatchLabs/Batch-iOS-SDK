//
//  BAWebserviceResponsePush.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSResponse.h>

/*!
 @class BAWebserviceResponsePush
 @abstract Response of a BAWebserviceQueryPush.
 @discussion Build and serialize the response to the query.
 */
@interface BAWSResponsePushToken : BAWSResponse <BAWSResponse>

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

@end
