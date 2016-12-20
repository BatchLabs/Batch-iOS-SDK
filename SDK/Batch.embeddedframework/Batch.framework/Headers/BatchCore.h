//
//  BatchCore.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BatchUserProfile.h"
#import "BatchLogger.h"

/*!
 Default placement
 */
#define BatchPlacementDefault @"DEFAULT"

/*!
 @class Batch
 @abstract Call for all you need for Batch usage in your application.
 @discussion Actions you can perform in Batch.
 @version v1.7.3
 @availability from iOS 8.0
 */
@interface Batch : NSObject

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method startWithAPIKey:
 @abstract Activate the whole Batch system.
 @discussion Call this method in application:didFinishLaunchingWithOptions: of your UIApplicationDelegate
 @discussion You can call this method from any thread, the start process is execute in background.
 @param key    :   Your API private key.
 */
+ (void)startWithAPIKey:(NSString *)key NS_AVAILABLE_IOS(8_0);

/*!
 @method handleURL:
 @abstract Give the URL to Batch systems.
 @discussion Call this method in application:openURL:sourceApplication:annotation: of your UIApplicationDelegate
 @discussion You can call this method from any thread.
 @param url         :   The input URL. Batch handle only it's own URL scheme and ignore others.
 @return YES if Batch take care of this URL, No otherwise.
 @warning The delegate methods is always called in the main thread!
 */
+ (BOOL)handleURL:(NSURL *)url __attribute__((warn_unused_result)) NS_AVAILABLE_IOS(8_0);

/*!
 @method isRunningInDevelopmentMode
 @abstract Test if Batch is running in development mode.
 @discussion You can call this method from any thread.
 @return YES if Batch is Running AND if it uses a development API key.
 */
+ (BOOL)isRunningInDevelopmentMode __attribute__((warn_unused_result)) NS_AVAILABLE_IOS(8_0);

/*!
 @method defaultUserProfile
 @abstract Access the default user profile object.
 @discussion You can call this method from any thread.
 @return The unique instance of this object. @see BatchUserProfile
 */
+ (BatchUserProfile *)defaultUserProfile __attribute__((warn_unused_result, deprecated("Please use Batch User instead"))) NS_AVAILABLE_IOS(8_0);

/*!
 @method setUseIDFA:
 @abstract Set if Batch can try to use IDFA (default = YES)
 @discussion Setting this to NO have a negative impact on offer delivery and restore.
 @param use :   YES if Batch can try to use the IDFA, NO if you don't want Batch to use the IDFA.
 @warning You should only use it if you know what you are doing.
 */
+ (void)setUseIDFA:(BOOL)use NS_AVAILABLE_IOS(8_0);

/*!
 @method setUseAdvancedDeviceInformation:
 @abstract Set if Batch can use advanced device identifiers (default = YES)
 @discussion Advanced device identifiers include information about the device itself, but nothing that
 directly identify the user, such as but not limited to:
 - Device model
 - Device brand
 - Carrier name
 - IDFV

 Setting this to false have a negative impact on core Batch features
 You should only use it if you know what you are doing.
 
 @param use :   YES if Batch can try to use advanced device information, NO if you don't
 @warning Disabling this does not automatically disable IDFA collection, please use the appropriate methods to control this.
 */
+ (void)setUseAdvancedDeviceInformation:(BOOL)use NS_AVAILABLE_IOS(8_0);

/*!
 @method setLoggerDelegate:
 @abstract Set if Batch should send its logs to a custom object of yours.
 @discussion Be careful with your implementation: setting this can impact stability and performance
 @param loggerDelegate : An object implementing BatchLoggerDelegate. Weakly retained.
 @warning You should only use it if you know what you are doing.
 */
+ (void)setLoggerDelegate:(id<BatchLoggerDelegate>)loggerDelegate NS_AVAILABLE_IOS(8_0);

@end
