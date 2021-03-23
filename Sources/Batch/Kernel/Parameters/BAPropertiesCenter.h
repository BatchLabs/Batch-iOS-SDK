//
//  BAPropertiesCenter.h
//  Core
//
//  Copyright (c) 2012 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Batch/BANotificationAuthorization.h>

/*!
 @class BAPropertiesCenter
 @abstract Accessor for application data.
 @discussion Provide a set of data, device, system ...
 */
@interface BAPropertiesCenter : NSObject

+ (nullable NSString *)valueForShortName:(nonnull NSString *)selectorString;

/**
 For tests
 */
- (nonnull NSString *)notifType;
- (nonnull NSString *)notifTypeFallback;
- (nullable BANotificationAuthorizationSettings *)notificationAuthorizationSettings;

@end
