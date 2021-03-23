//
//  BAWebserviceResponseNewStart.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSResponse.h>

/*!
 @class BAWebserviceResponseNewStart
 @abstract Response of a BAWebserviceQueryNewStart.
 @discussion Build and serialize the response to the query.
 */
@interface BAWSResponseStart : BAWSResponse <BAWSResponse>

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

@end
