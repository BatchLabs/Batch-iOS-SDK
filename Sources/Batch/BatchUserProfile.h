//
//  BatchUserProfile.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Describe a complete user profile.
 Use this object to access all user info.
 */
@interface BatchUserProfile : NSObject

/**
 Set a custom user identifier to Batch, you should use this method if you have your own login system.
 
 @warning Be careful: Do not use it if you don't know what you are doing, giving a bad custom user ID can result in failure of targeted push notifications delivery.
 
 @deprecated
 */
@property (strong, nonatomic) NSString *customIdentifier __attribute__((deprecated("Please use Batch User instead")));

/**
 The application language, default value is the device language.
 Set to nil to reset to default value.
 
 @deprecated
 */
@property (strong, nonatomic) NSString *language __attribute__((deprecated("Please use Batch User instead")));

/**
 The application region, default value is the device region.
 Set to nil to reset to default value.
 
 @deprecated
 */
@property (strong, nonatomic) NSString *region __attribute__((deprecated("Please use Batch User instead")));

@end
