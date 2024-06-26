//
//  BAUserProfile.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BAUserProfile
 @abstract Describe a complete user profile.
 @discussion Use this object to access all the user info.
 */
@interface BAUserProfile : NSObject <NSCoding>

/*!
 @property version
 @abstract The data version
 */
@property (strong, nonatomic, readonly, nonnull) NSNumber *version;

/*!
 @property customIdentifier
 @abstract Access a custom user identifier to Batch, you should use this method if you have your own login system.
 @warning  Be carefull: Do not use it if you don't know what you are doing, giving a bad custom user ID can result in
 failure into offer delivery and restore.
 */
@property (strong, nonatomic, nullable) NSString *customIdentifier;

/*!
 @property language
 @abstract The custom application language.
 @discussion Set to nil to reset the custom setting.
 */
@property (strong, nonatomic, nullable) NSString *language;

/*!
 @property region
 @abstract The custom application region, default value is the device region.
 @discussion Set to nil to reset the custom setting.
 */
@property (strong, nonatomic, nullable) NSString *region;

/*!
 @method defaultUserProfile
 @abstract Access the default user profile object.
 @discussion You can call this method from any thread.
 @return The unique instance of this object. @see BatchUserProfile
 */
+ (BAUserProfile *_Nonnull)defaultUserProfile __attribute__((warn_unused_result));

/*!
 @method dictionaryRepresentation
 @abstract Key-Value dictionary representation of a user profile.
 @return The dictionary representation.
 */
- (NSDictionary *_Nonnull)dictionaryRepresentation __attribute__((warn_unused_result));

@end
