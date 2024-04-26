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
 Open URL using UIApplication.
 Handles compatibility: prefer this method over calling UIApplication directly
 */
+ (void)openURLWithUIApplication:(NSURL *)URL;

/**
 Opens the given deeplink. Allows for developers to override the behavior using a deeplink delegate.

 @param deeplink Doesn't need to be a valid NSURL, as it can be overriden.
 @param inApp Set to YES to open the url in app using a SFSafariViewController if available.
 */
- (void)openDeeplink:(NSString *)deeplink inApp:(BOOL)inApp;

@end
