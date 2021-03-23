//
//  BAWebserviceQueryPush.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWSQuery.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class BAWebserviceQueryPush
 @abstract Query that gives the push token.
 @discussion Used to enable push
 */
@interface BAWSQueryPushToken : BAWSQuery <BAWSQuery>

/*!
 @abstract Standard constructor.
 @param token       :   Token to send.
 @param production  :   Is the token APNS production or sandbox?
 @return Instance or nil.
 */
- (instancetype)initWithToken:(NSString *)token andIsProduction:(BOOL)production;

@end

NS_ASSUME_NONNULL_END
