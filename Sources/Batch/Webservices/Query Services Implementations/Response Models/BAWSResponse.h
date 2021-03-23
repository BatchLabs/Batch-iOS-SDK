//
//  BAWSResponse.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAResponseHelper.h>

/*!
 @protocol BAWSResponse
 @abstract Common implementation for responses.
 */
@protocol BAWSResponse <NSObject>

@required
/*!
 @method reference
 @abstract Response identification.
 @return Unique response reference.
 */
- (NSString *)reference;

@end


/*!
 @class BAWSResponse
 @abstract Basic response implementation.
 @discussion Do not instanciate this class directly, use one of the typed responses.
 */
@interface BAWSResponse : NSObject <BAWSResponse>

/*!
 @property reference
 @abstract Response unique reference.
 */
@property (strong, readonly) NSString *reference;

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithResponse:
 @abstract Default constructor.
 @param response    :   Webservice query response object.
 @return Instance of nil.
 */
- (instancetype)initWithResponse:(NSDictionary *)response __attribute__((warn_unused_result));

@end
