//
//  BAResponseHelper.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BAResponseHelper
 @abstract Response helper for Start webservice.
 @discussion Provide helpfull functions for Start webservice.
 */
@interface BAResponseHelper : NSObject

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method checkResponse:
 @abstract Check the validity of the response.
 @param response    :   The dictionary representation of the response.
 @return An error if something goes wrong, nil otherwise.
 */
+ (NSError *)checkResponse:(NSDictionary *)response;

@end
