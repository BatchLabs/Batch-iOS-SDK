//
//  BAPushMessage.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BAPushMessage
 @abstract Push message formated.
 @discussion Parse the message user info.
 */
@interface BAPushPayload : NSObject

/*!
 @property rawDeeplink
 @abstract Deeplink string
 */
@property (strong, readonly) NSString *rawDeeplink;

@property (nonatomic, readonly) BOOL openDeeplinksInApp;

/*!
 @property data
 @abstract Data, can contain the campaign identifier and the scheme (optional, can be nil).
 */
@property (strong, readonly) NSDictionary *data;

/*!
 @property openEventData
 @abstract Data to track when tracking an open event
 */
@property (strong, readonly) NSDictionary *openEventData;

- (instancetype)initWithUserInfo:(NSDictionary *)info;

- (BOOL)requiresReadReceipt;

@end
