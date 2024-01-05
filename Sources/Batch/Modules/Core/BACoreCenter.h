//
//  BACoreCenter.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAConfiguration.h>
#import <Batch/BAStatus.h>

#import <Batch/BACenterMulticastDelegate.h>

@class BAOffer;

/*!
 @class BACoreCenter
 @abstract Central control point of Batch services.
 @discussion Used for managing the runtime of the library.
 */
@interface BACoreCenter : NSObject <BACenterProtocol>

// SDK Version (X.Y.Z)
@property (class, readonly) NSString *sdkVersion;

/*!
 @property status
 @abstract General status of Batch library.
 */
@property (strong, nonatomic) BAStatus *status;

/*!
 @property configuration
 @abstract General configuration parameters of the library.
 */
@property (strong, nonatomic) BAConfiguration *configuration;

/*!
 @method instance
 @abstract Instance method.
 @return BACoreCenter singleton.
 */
+ (BACoreCenter *)instance __attribute__((warn_unused_result));

/*!
 @method startWithAPIKey:
 @abstract Activate the whole Batch system.
 @discussion Call this method in application:didFinishLaunchingWithOptions: of your UIApplicationDelegate
 @discussion You can call this method from any thread, the start process is execute in background.
 @param key    :   Your API private key.
 */
+ (void)startWithAPIKey:(NSString *)key;

/*!
 @method handleURL:
 @abstract Give the URL to Batch systems.
 @discussion Call this method in application:openURL:sourceApplication:annotation: of your UIApplicationDelegate
 @discussion You can call this method from any thread.
 @param url         :   The input URL.
 @return YES if Batch take care of this URL, No otherwise.
 @warning The delegate methods is always called in the main thread!
 */
+ (BOOL)handleURL:(NSURL *)url __attribute__((warn_unused_result));

/*!
 @method isRunningInDevelopmentMode
 @abstract Test if Batch is running in development mode.
 @discussion You can call this method from any thread.
 @return YES if Batch is Running AND if it uses a development API key.
 */
+ (BOOL)isRunningInDevelopmentMode __attribute__((warn_unused_result));

/*!
 Open URL using UIApplication.
 Handles compatibility: prefer this method over calling UIApplication directly
 */
+ (void)openURLWithUIApplication:(NSURL *)URL;

/*!
 @method setUseAdvancedDeviceInformation:
 @abstract Set if Batch can use advanced device identifiers (default = YES)
 @discussion Advanced device identifiers include information about the device itself, but nothing that
 directly identify the user, such as but not limited to:
 - Device model
 - Device brand
 - Carrier name

 Setting this to false have a negative impact on core Batch features
 You should only use it if you know what you are doing.

 @param use :   YES if Batch can try to use advanced device information, NO if you don't want to
 */
+ (void)setUseAdvancedDeviceInformation:(BOOL)use;

/**
 Opens the given deeplink. Allows for developers to override the behavior using a deeplink delegate.

 @param deeplink Doesn't need to be a valid NSURL, as it can be overriden.
 @param inApp Set to YES to open the url in app using a SFSafariViewController if available.
 */
- (void)openDeeplink:(NSString *)deeplink inApp:(BOOL)inApp;

@end
